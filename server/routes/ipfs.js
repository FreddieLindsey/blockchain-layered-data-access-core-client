import express from 'express'
const router = express.Router()

router.get('/', (req, res, next) => {
  res.json({ status: 'ok' })
})

export const ipfs = router
