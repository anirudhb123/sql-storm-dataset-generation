
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS original_title,
        m.production_year,
        COALESCE(m2.title, 'N/A') AS sequel_title
    FROM 
        aka_title m
    LEFT JOIN 
        aka_title m2 ON m.episode_of_id = m2.id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS original_title,
        m.production_year,
        COALESCE(m2.title, 'N/A') AS sequel_title
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON mh.movie_id = m.episode_of_id
    LEFT JOIN 
        aka_title m2 ON m.episode_of_id = m2.id
)

SELECT 
    mh.original_title,
    mh.production_year,
    mh.sequel_title,
    COUNT(c.id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    AVG(p.info_length) AS avg_person_info_length,
    COUNT(DISTINCT CASE WHEN c.movie_id IS NOT NULL THEN c.movie_id END) AS movies_with_roles
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info c ON c.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    LATERAL (
        SELECT 
            LENGTH(info) AS info_length
        FROM 
            person_info pi
        WHERE 
            pi.person_id = ak.person_id
    ) p ON TRUE
GROUP BY 
    mh.original_title, mh.production_year, mh.sequel_title
HAVING 
    COUNT(c.id) > 0
ORDER BY 
    mh.production_year DESC, 
    cast_count DESC;
