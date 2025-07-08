
WITH MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        0 AS level 
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        mk.linked_movie_id AS movie_id, 
        t.title, 
        mh.level + 1 
    FROM 
        movie_link mk
    JOIN 
        title t ON mk.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = mk.movie_id 
    WHERE 
        t.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        m.id, 
        m.title, 
        m.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year BETWEEN 2020 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    t.production_year,
    t.cast_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
JOIN 
    TopMovies t ON mh.movie_id = t.id
WHERE 
    mh.level IN (0, 1) 
ORDER BY 
    t.production_year, mh.level, t.cast_count DESC;
