
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
LatestMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
),
PersonGenre AS (
    SELECT 
        ci.person_id,
        kt.kind AS genre,
        COUNT(DISTINCT mt.id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    JOIN 
        kind_type kt ON mt.kind_id = kt.id
    GROUP BY 
        ci.person_id, kt.kind
),
TopGenres AS (
    SELECT 
        pg.person_id,
        pg.genre,
        pg.movie_count,
        ROW_NUMBER() OVER (PARTITION BY pg.person_id ORDER BY pg.movie_count DESC) AS genre_rank
    FROM 
        PersonGenre pg
)

SELECT 
    ak.name AS actor_name,
    lt.title AS latest_movie,
    lt.production_year,
    tg.genre AS top_genre,
    tg.movie_count AS top_genre_movie_count,
    COALESCE(tg.genre_rank, 0) AS top_genre_rank,
    COALESCE((SELECT COUNT(*) 
              FROM movie_keyword mk 
              JOIN keyword k ON mk.keyword_id = k.id 
              WHERE mk.movie_id = lt.movie_id AND k.keyword LIKE 'Award%'), 0) AS award_related_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    LatestMovies lt ON ci.movie_id = lt.movie_id AND lt.rn = 1
LEFT JOIN 
    TopGenres tg ON ak.person_id = tg.person_id AND tg.genre_rank = 1
WHERE 
    ak.name IS NOT NULL
ORDER BY 
    lt.production_year DESC, actor_name;
