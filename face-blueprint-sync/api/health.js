module.exports = (req, res) => {
  res.status(200).json({ ok: true, env_has_api_bearer: !!process.env.API_BEARER });
};
