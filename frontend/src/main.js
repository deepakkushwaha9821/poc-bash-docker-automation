async function fetchHealth() {
  const statusEl = document.getElementById('backend-status');
  const logOutputEl = document.getElementById('log-output');

  statusEl.className = 'value loading';
  statusEl.textContent = 'Checking...';

  try {
    const res = await fetch('/api/health');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();

    const branchEl = document.getElementById('branch-info');
    if (branchEl) branchEl.textContent = 'poc-git';

    statusEl.className = 'value healthy';
    statusEl.textContent = data.message ? `Active (${data.message})` : 'Active';
    logOutputEl.textContent = JSON.stringify(data, null, 2);
  } catch (err) {
    statusEl.className = 'value error';
    statusEl.textContent = 'Offline / Error';
    logOutputEl.textContent = `Error connecting to backend: ${err.message}`;
  }
}

// Initial check on load
fetchHealth();
