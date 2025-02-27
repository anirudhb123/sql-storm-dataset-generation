WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Filter for modern movies
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        MovieHierarchy m
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id 
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.company_count,
        mi.keyword_count,
        RANK() OVER (ORDER BY mi.company_count DESC, mi.keyword_count DESC) AS rank
    FROM 
        MovieInfo mi
    WHERE 
        mi.company_count > 5 -- Filter for movies with more than 5 companies
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(NULLIF(tm.company_count, 0), 'N/A') AS company_count,
    COALESCE(NULLIF(tm.keyword_count, 0), 'N/A') AS keyword_count
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10 -- Get top 10 movies
ORDER BY 
    tm.rank;
