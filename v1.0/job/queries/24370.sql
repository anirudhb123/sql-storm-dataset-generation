WITH RECURSIVE movie_season AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        ROW_NUMBER() OVER (PARTITION BY t.season_nr ORDER BY t.episode_nr) AS episode_order
    FROM 
        aka_title t
    JOIN 
        title m ON t.movie_id = m.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'tv series')
),
cast_details AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        r.role AS role_name,
        COALESCE(MAX(m.production_year), 0) AS last_movie_year
    FROM 
        cast_info c 
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        aka_title m ON c.movie_id = m.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.id, a.name, r.role
),
notable_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title
    HAVING 
        COUNT(DISTINCT kw.keyword) > 5
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    m.season_nr,
    m.episode_nr,
    cd.actor_name,
    cd.role_name,
    cd.last_movie_year,
    nm.keyword_count
FROM 
    movie_season m
JOIN 
    cast_details cd ON m.movie_id = cd.cast_id
LEFT JOIN 
    notable_movies nm ON m.movie_id = nm.movie_id
WHERE 
    (m.season_nr IS NULL OR m.season_nr != 0)
    AND (cd.last_movie_year IS NULL OR cd.last_movie_year < 2020)
ORDER BY 
    m.production_year DESC, 
    m.season_nr ASC,
    m.episode_nr ASC
LIMIT 50;
