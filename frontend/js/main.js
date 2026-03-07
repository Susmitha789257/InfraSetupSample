function register() {
    fetch("/api/register/", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            username: document.getElementById("reg-username").value,
            password: document.getElementById("reg-password").value
        })
    })
    .then(res => res.json())
    .then(data => {
        if (data.message) {
            alert(data.message);
            window.location.href = "index.html";
        } else {
            alert(data.error);
        }
    })
    .catch(err => {
        alert("Server error");
        console.log(err);
    });
}

function login() {
    fetch("/api/login/", {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            username: document.getElementById("login-username").value,
            password: document.getElementById("login-password").value
        })
    })
    .then(res => res.json())
    .then(data => {
        if (data.message) {
            // SUCCESS
            window.location.href = "welcome.html";
        } else {
            // FAILURE
            alert(data.error);
        }
    })
    .catch(err => {
        alert("Server error");
        console.log(err);
    });
}

function logout() {
    window.location.href = "index.html";
}

