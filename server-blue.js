
const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('🌊 Blue Version'));
app.listen(3000, () => console.log('Blue running on port 3000'));
