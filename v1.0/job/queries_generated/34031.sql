WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CAST(m.title AS TEXT) AS full_title,
        NULL::INTEGER AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        CONCAT(mh.full_title, ' -> ', e.title) AS full_title,
        mh.movie_id AS parent_movie_id
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.full_title,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    AVG(COALESCE(m_info.info::INTEGER, 0)) AS average_movie_info,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank_within_year
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_info m_info ON mh.movie_id = m_info.movie_id AND m_info.info_type_id = 1
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.full_title
HAVING 
    COUNT(DISTINCT ci.person_id) > 5 OR AVG(COALESCE(m_info.info::INTEGER, 0)) > 3
ORDER BY 
    mh.production_year DESC, mh.title
LIMIT 50;

This SQL query includes:
- A recursive Common Table Expression (CTE) to create a hierarchy of movies and their episodes.
- Multiple outer joins to gather related information from related tables.
- String aggregation to concatenate company names associated with each movie.
- Counting distinct actors and averaging certain movie info as numeric values.
- Utilization of window functions for ranking movies within their production year.
- A HAVING clause to filter results based on a minimum number of actors or average information metrics.
