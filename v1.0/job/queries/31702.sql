
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level,
        NULL AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    UNION ALL
    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT p.name, ', ') AS actors,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        mh.movie_title,
        mh.level,
        mi.production_year,
        mi.keywords,
        mi.actors,
        mi.company_count,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mi.production_year DESC) AS rn
    FROM 
        MovieHierarchy mh
    JOIN 
        MovieInfo mi ON mh.movie_id = mi.movie_id
)
SELECT 
    tm.movie_title,
    tm.level,
    tm.production_year,
    COALESCE(tm.keywords, 'No keywords') AS keywords,
    COALESCE(tm.actors, 'No actors') AS actors,
    tm.company_count
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 5
ORDER BY 
    tm.level, tm.production_year DESC;
