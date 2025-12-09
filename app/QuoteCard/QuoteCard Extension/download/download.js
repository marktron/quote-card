// Get image data from URL parameters
const params = new URLSearchParams(window.location.search);
const imageData = params.get('data');
if (imageData) {
    const img = document.getElementById('image');
    img.src = imageData;
    // Trigger automatic download
    const link = document.createElement('a');
    link.href = imageData;
    link.download = `quotecard-${Date.now()}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}
