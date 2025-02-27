WITH RECURSIVE movie_hierarchy AS (
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
        mv.id,
        mv.title,
        mv.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        title mv ON ml.linked_movie_id = mv.id
)
, cast_summary AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        SUM(CASE WHEN cr.role = 'Actor' THEN 1 ELSE 0 END) AS total_actors,
        SUM(CASE WHEN cr.role = 'Director' THEN 1 ELSE 0 END) AS total_directors
    FROM 
        cast_info ca
    JOIN 
        role_type cr ON ca.role_id = cr.id
    GROUP BY 
        ca.movie_id
)
, movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
, filtered_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cs.total_cast,
        cs.total_actors,
        cs.total_directors,
        mk.keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_summary cs ON mh.movie_id = cs.movie_id
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
    WHERE 
        (cs.total_cast > 10 OR cs.total_cast IS NULL) 
        AND mh.production_year BETWEEN 2000 AND 2023
        AND COALESCE(mk.keywords, '') <> '' 
)

SELECT 
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.total_actors,
    fm.total_directors,
    COALESCE(fm.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN fm.production_year = 2023 THEN 'Latest Release'
        ELSE 'Classic'
    END as release_status
FROM 
    filtered_movies fm
ORDER BY 
    fm.total_cast DESC,
    fm.production_year DESC
LIMIT 50;

-- Exploring edge cases
-- This query retrieves a list of movies from 2000 to 2023 with a sufficient number of cast members,
-- including those that have been released in recent years. The use of CTEs with recursive logic,
-- string aggregation for keywords, and conditional logic for release classification demonstrates 
-- a complex SQL structure. The outer joins ensure that we include movies even if they have no cast or keywords.
