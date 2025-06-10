const express = require("express");
const axios = require("axios");
const cors = require("cors");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

 
app.post("/reset", async (req, res) => {
  const { from, to, subject, html } = req.body;

  // Validasi input
  if (!from || !to || !subject || !html) {
    return res.status(400).json({
      message: "Semua field wajib diisi: from, to, subject, html.",
    });
  }

  // Periksa API Key Mailersend
  const apiKey = process.env.MAILERSEND_API_KEY;
  if (!apiKey) {
    console.error("❌ API Key Mailersend tidak ditemukan di .env");
    return res.status(500).json({
      message: "Konfigurasi server salah: API Key tidak tersedia.",
    });
  }

  try {
    // Mengirim permintaan ke Mailersend API
    const response = await axios.post(
      "https://api.mailersend.com/v1/email",
      {
        from: { email: from },
        to: [{ email: to }],
        subject: subject,
        html: html, // HTML body berisi kode OTP
      },
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
      }
    );

    console.log("✅ Email berhasil dikirim:", response.data);
    res.status(200).json({ message: "Email OTP berhasil dikirim." });
  } catch (error) {
    const status = error.response?.status || 500;
    const data = error.response?.data || error.message;

    console.error("❌ Gagal mengirim email");
    console.error("Status:", status);
    console.error("Response:", data);

    res.status(status).json({
      message: "Terjadi kesalahan saat mengirim email.",
      error: data,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`✅ Proxy listening on port ${PORT}`));
