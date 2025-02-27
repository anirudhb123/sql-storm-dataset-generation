WITH Recents AS (
    SELECT
        ak.name AS aka_name,
        t.title AS movie_title,
        c.id AS cast_id,
        p.id AS person_id,
        p.name AS person_name,
        p.gender AS person_gender,
        t.production_year AS prod_year
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    JOIN name p ON ak.person_id = p.imdb_id
    WHERE t.production_year >= 2020
),
MovieStats AS (
    SELECT
        movie_title,
        COUNT(*) AS total_cast,
        COUNT(DISTINCT person_id) AS unique_actors,
        STRING_AGG(DISTINCT person_name, ', ') AS actor_list
    FROM Recents
    GROUP BY movie_title
),
AkaStats AS (
    SELECT
        ak.name AS aka_name,
        COUNT(DISTINCT p.id) AS associated_people
    FROM aka_name ak
    JOIN name p ON ak.person_id = p.imdb_id
    GROUP BY ak.name
)
SELECT
    ms.movie_title,
    ms.total_cast,
    ms.unique_actors,
    ms.actor_list,
    as1.aka_name,
    as1.associated_people
FROM MovieStats ms
JOIN AkaStats as1 ON ms.actor_list LIKE '%' || as1.aka_name || '%'
ORDER BY ms.total_cast DESC, ms.movie_title;
