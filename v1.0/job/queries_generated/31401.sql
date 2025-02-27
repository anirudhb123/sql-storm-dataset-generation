WITH RECURSIVE ActorMovies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM cast_info AS c
    JOIN aka_title AS t
        ON c.movie_id = t.id
    WHERE t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
),
TopActors AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT am.movie_rank) AS movie_count
    FROM ActorMovies AS am
    GROUP BY a.person_id
    HAVING COUNT(DISTINCT am.movie_rank) >= 5
),
MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(COUNT(mk.keyword_id), 0) AS keyword_count,
        COALESCE(AVG(mi.info), 0) AS avg_info_length
    FROM aka_title AS t
    LEFT JOIN movie_keyword AS mk
        ON t.id = mk.movie_id
    LEFT JOIN movie_info AS mi
        ON t.id = mi.movie_id
    WHERE t.production_year BETWEEN 2000 AND 2020
    GROUP BY t.id
),
ActorsWithMovies AS (
    SELECT 
        a.name,
        am.title,
        am.production_year
    FROM aka_name AS a
    JOIN cast_info AS c
        ON a.person_id = c.person_id
    JOIN aka_title AS am
        ON c.movie_id = am.id
    WHERE am.production_year IN (SELECT production_year FROM MovieStats WHERE keyword_count > 2)
)
SELECT 
    a.name,
    COUNT(DISTINCT am.title) AS movies_participated,
    AVG(ms.avg_info_length) AS average_info_length
FROM ActorsWithMovies AS a
JOIN MovieStats AS ms
    ON a.title = ms.title
WHERE a.name IS NOT NULL
GROUP BY a.name
HAVING COUNT(DISTINCT am.title) > 3
ORDER BY average_info_length DESC
LIMIT 10
OFFSET 5;
