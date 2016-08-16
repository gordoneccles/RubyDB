CREATE TABLE farmers (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

CREATE TABLE coops (
  id INTEGER PRIMARY KEY,
  location VARCHAR(255) NOT NULL,
  farmer_id INTEGER,

  FOREIGN KEY(farmer_id) REFERENCES farmer(id)
);

CREATE TABLE chickens (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  coop_id INTEGER,

  FOREIGN KEY(coop_id) REFERENCES coop(id)
);


INSERT INTO
  farmers (id, name)
VALUES
  (1, "Doris"), (2, "John"), (3, "Agamemnon");

INSERT INTO
  coops (id, location, farmer_id)
VALUES
  (1, "Way far away", 1),
  (2, "Right outside", 2),
  (3, "Living room", 1),
  (4, "England", 2),
  (5, "Backyard", 3);

INSERT INTO
  chickens (id, name, coop_id)
VALUES
  (1, "Cluck", 1),
  (2, "Cluck cluck", 2),
  (3, "Bock", 2),
  (4, "BOOOOCKK", 3),
  (5, "Hiss", 4),
  (6, "Ribbit", 4),
  (7, "Moo", 5);
