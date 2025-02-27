WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5 -- limit hierarchy depth to avoid excessive recursion
),

InterestingMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS year_rank
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        movie_keyword AS mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

DirectorInfo AS (
    SELECT 
        ci.movie_id,
        ca.name AS director_name,
        ci.person_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ca ON ci.person_id = ca.person_id
    WHERE 
        ci.role_id IN (SELECT id FROM role_type WHERE role = 'director') -- Filtering for directors
),

FilteredMovies AS (
    SELECT 
        im.movie_id,
        im.title,
        im.production_year,
        di.director_name,
        im.keyword_count
    FROM 
        InterestingMovies AS im
    LEFT JOIN 
        DirectorInfo AS di ON im.movie_id = di.movie_id
    WHERE 
        di.role_order = 1 AND -- Get only the main director
        im.keyword_count > 5 -- Filtering movies with more than 5 keywords
)

SELECT 
    fm.title,
    fm.production_year,
    fm.director_name,
    fm.keyword_count,
    COALESCE(cn.country_code, 'Unknown') AS production_country
FROM 
    FilteredMovies AS fm
LEFT JOIN 
    movie_companies AS mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
ORDER BY 
    fm.production_year DESC,
    fm.keyword_count DESC;

-- This query produces a list of fascinating movies which have a main director, more than five keywords,
-- along with their production years and associated production countries, while also demonstrating various advanced SQL features.
