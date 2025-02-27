WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        title m ON ml.linked_movie_id = m.id
    WHERE 
        h.level < 5
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        RANK() OVER (PARTITION BY production_year ORDER BY COUNT(*) DESC) AS rank
    FROM 
        movie_keyword mk
    JOIN 
        aka_title at ON mk.movie_id = at.id
    GROUP BY 
        title, production_year
),
GenreCounts AS (
    SELECT 
        c.kind_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.kind_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 10
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    COALESCE(gc.movie_count, 0) AS genre_movie_count,
    th.rank AS production_rank
FROM 
    title t
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    GenreCounts gc ON t.kind_id = gc.kind_id
LEFT JOIN 
    TopMovies th ON t.title = th.title
WHERE 
    th.rank IS NOT NULL OR gc.movie_count IS NOT NULL
GROUP BY 
    t.title, t.production_year, gc.movie_count, th.rank
ORDER BY 
    t.production_year DESC, total_cast DESC
LIMIT 50;
