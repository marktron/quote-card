// Listen for download requests from parent
window.addEventListener('message', function(event) {
  console.log('Download helper received message:', event.data);
  if (event.data.type === 'DOWNLOAD') {
    console.log('Triggering download...');

    try {
      // Convert data URL to blob
      const base64Data = event.data.dataUrl.split(',')[1];
      const mimeType = event.data.dataUrl.split(',')[0].split(':')[1].split(';')[0];

      const byteCharacters = atob(base64Data);
      const byteNumbers = new Array(byteCharacters.length);
      for (let i = 0; i < byteCharacters.length; i++) {
        byteNumbers[i] = byteCharacters.charCodeAt(i);
      }
      const byteArray = new Uint8Array(byteNumbers);
      const blob = new Blob([byteArray], { type: mimeType });

      // Try using object URL
      const objectUrl = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = objectUrl;
      link.download = event.data.filename;
      link.style.display = 'none';
      document.body.appendChild(link);

      // Use setTimeout to ensure the link is in the DOM
      setTimeout(function() {
        link.click();
        document.body.removeChild(link);
        setTimeout(function() {
          URL.revokeObjectURL(objectUrl);
        }, 100);
        console.log('Download triggered');
      }, 0);
    } catch (error) {
      console.error('Download error:', error);
    }
  }
});

// Signal ready
console.log('Download helper loaded, signaling ready');
window.parent.postMessage({ type: 'READY' }, '*');
