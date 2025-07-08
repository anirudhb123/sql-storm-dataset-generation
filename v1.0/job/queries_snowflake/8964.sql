
WITH RecentMovies AS (
    SELECT DISTINCT m.id AS movie_id, m.title AS movie_title, m.production_year
    FROM aka_title m
    WHERE m.production_year >= 2020
), EncounteredPeople AS (
    SELECT DISTINCT c.person_id, a