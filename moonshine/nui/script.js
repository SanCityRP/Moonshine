let id = null

window.addEventListener('message', (e) => {
    if (e.data.type === "open") {
        id = e.data.id
        document.getElementById("container").style.display = "flex"
    }

    if (e.data.type === "update") {
        document.getElementById("temp").innerText = e.data.temp + "°C"
        document.getElementById("feedback").innerText = e.data.hint || ""
        document.getElementById("progress").innerText = "Progress: " + e.data.progress
    }

    if (e.data.type === "close") {
        document.getElementById("container").style.display = "none"
    }
})

document.getElementById("heat").oninput = (e) => {
    fetch(`https://${GetParentResourceName()}/control`, {
        method: "POST",
        body: JSON.stringify({
            id: id,
            type: "heat",
            value: parseFloat(e.target.value)
        })
    })
}

document.getElementById("close").onclick = () => {
    fetch(`https://${GetParentResourceName()}/close`, {
        method: "POST",
        body: JSON.stringify({ id: id })
    })
}