WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CAST(NULL AS INTEGER) AS parent_movie_id,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1 AS level
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON mh.movie_id = e.episode_of_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(a.name, 'Unknown Actor') AS lead_actor,
    COUNT(DISTINCT mcast.person_id) AS total_cast,
    SUM(CASE WHEN mcomp.company_id IS NOT NULL THEN 1 ELSE 0 END) AS total_companies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.production_year DESC) AS row_num
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info mcast ON mh.movie_id = mcast.movie_id
LEFT JOIN 
    aka_name a ON mcast.person_id = a.person_id
LEFT JOIN 
    movie_companies mcomp ON mh.movie_id = mcomp.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.level = 0  
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, a.name
HAVING 
    COUNT(DISTINCT mcast.person_id) > 1  
ORDER BY 
    mh.production_year DESC, mh.title;