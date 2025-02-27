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
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ca ON mh.movie_id = ca.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT ca.person_id) > 10
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS movie_keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_names, '{}') AS actor_names,
    COALESCE(md.movie_keywords, 'No Keywords') AS movie_keywords
FROM 
    MovieDetails md
JOIN 
    (SELECT DISTINCT 
        person_id 
     FROM 
        cast_info 
     WHERE 
        role_id IS NOT NULL) AS UniqueActors ON TRUE
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
