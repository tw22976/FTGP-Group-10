const express = require('express');
const bodyParser = require('body-parser');
const { MongoClient } = require('mongodb');

const app = express();
const port = process.env.PORT || 3000;

const uri = 'mongodb+srv://visaltheekshana:ftgpg_10@cluster0.xssp8za.mongodb.net/?retryWrites=true&w=majority';

app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public'));

app.get('/', (req, res) => {
  res.sendFile(__dirname + '/index.html');
});

app.post('/submit', async (req, res) => {
  const { name, age } = req.body;

  const client = new MongoClient(uri);
  try {
    await client.connect();
    const result = await client
      .db('test')
      .collection('users')
      .insertOne({ name, age: parseInt(age) });
    console.log('Inserted document with _id:', result.insertedId);
  } catch (error) {
    console.error('Error:', error);
  } finally {
    await client.close();
  }

  res.redirect('/');
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
