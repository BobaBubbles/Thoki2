#[cfg(windows)]
use {
    std::{mem, ptr},
    windows_sys::Win32::Foundation::CloseHandle,
    windows_sys::Win32::System::JobObjects::{
        AssignProcessToJobObject, CreateJobObjectW, JobObjectCpuRateControlInformation,
        SetInformationJobObject, JOBOBJECT_CPU_RATE_CONTROL_INFORMATION,
        JOB_OBJECT_CPU_RATE_CONTROL_ENABLE, JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP,
    },
    windows_sys::Win32::System::Threading::GetCurrentProcess,
};

/// Sets CPU limit for the current process
///
/// # Arguments
/// * `cpu_limit` - CPU limit percentage (1-100)
///
/// # Returns
/// * `true` if CPU limit was set successfully
/// * `false` if there was an error
#[cfg(windows)]
pub fn set_cpu_limit(cpu_limit: u32) -> bool {
    // Validate CPU limit value, which must be between 1 and 100 inclusive.
    if !(1..=100).contains(&cpu_limit) {
        log::error!("Invalid CPU limit value. Must be between 1 and 100.");
        return false;
    }

    unsafe {
        // Create a job object to apply the CPU limit to the current process.
        let h_job = CreateJobObjectW(ptr::null_mut(), ptr::null_mut());
        if h_job == std::ptr::null_mut() {
            log::error!("CreateJobObjectW failed with error: {}", std::io::Error::last_os_error());
            return false;
        }

        // Set up the CPU rate control information.
        // The CpuRate is a percentage multiplied by 100, so a value of 5000 means 50%.
        let mut cpu_rate_info: JOBOBJECT_CPU_RATE_CONTROL_INFORMATION = mem::zeroed();
        cpu_rate_info.ControlFlags =
            JOB_OBJECT_CPU_RATE_CONTROL_ENABLE | JOB_OBJECT_CPU_RATE_CONTROL_HARD_CAP;
        cpu_rate_info.Anonymous.CpuRate = cpu_limit * 100;

        // Apply the CPU limit to the job object.
        let result = SetInformationJobObject(
            h_job,
            JobObjectCpuRateControlInformation,
            &mut cpu_rate_info as *mut _ as *mut _,
            mem::size_of::<JOBOBJECT_CPU_RATE_CONTROL_INFORMATION>() as u32,
        );

        if result == 0 {
            log::error!("SetInformationJobObject failed with error: {}", std::io::Error::last_os_error());
            CloseHandle(h_job);
            return false;
        }

        // Assign the current process to the job object.
        let h_process = GetCurrentProcess();
        let result = AssignProcessToJobObject(h_job, h_process);
        if result == 0 {
            log::error!("AssignProcessToJobObject failed with error: {}", std::io::Error::last_os_error());
            CloseHandle(h_job);
            return false;
        }

        log::info!("CPU limit set to {}%", cpu_limit);
        // Note: We don't close h_job here as it needs to remain open for the job to stay active.
        true
    }
}

#[cfg(target_os = "linux")]
pub fn set_cpu_limit(cpu_limit: u32) -> bool {
    use std::fs::{create_dir_all, write};
    use std::process;

    // Validate CPU limit value, which must be between 1 and 100 inclusive.
    if !(1..=100).contains(&cpu_limit) {
        log::error!("Invalid CPU limit value. Must be between 1 and 100.");
        return false;
    }

    let pid = process::id();
    let cgroup_path = format!("/sys/fs/cgroup/thoki_{}", pid);

    // Create cgroup directory
    if let Err(e) = create_dir_all(&cgroup_path) {
        log::error!("Failed to create cgroup directory: {}", e);
        return false;
    }

    // Set CPU limit: cpu.max = <quota> <period>
    // For example, to set 20%: quota = period * 20 / 100
    let period = 100_000u64; // 100ms (default)
    let quota = period * cpu_limit as u64 / 100;
    let cpu_max = format!("{} {}", quota, period);
    
    if let Err(e) = write(format!("{}/cpu.max", cgroup_path), cpu_max) {
        log::error!("Failed to set CPU limit to cgroup: {}", e);
        return false;
    }

    // Add this process to the cgroup
    if let Err(e) = write(format!("{}/cgroup.procs", cgroup_path), pid.to_string()) {
        log::error!("Failed to add process to cgroup: {}", e);
        return false;
    }

    log::info!("CPU limit set to {}%", cpu_limit);
    true
}

#[cfg(not(any(windows, target_os = "linux")))]
pub fn set_cpu_limit(cpu_limit: u32) -> bool {
    use crate::helpers::helpers::get_os_type;
    let os_type = get_os_type();
    log::error!("CPU limit of {}% not supported on {}", cpu_limit, os_type);
    false
}
