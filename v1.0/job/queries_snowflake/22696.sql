
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(p.name, 'Unknown') AS director_name,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name p ON mc.company_id = p.imdb_id
    WHERE 
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(p.name, 'Unknown') AS director_name,
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name p ON mc.company_id = p.imdb_id
)

SELECT 
    mh.depth,
    mh.movie_id,
    mh.title,
    mh.production_year,
    LISTAGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.person_id) AS cast_count,
    AVG(CASE WHEN c.person_role_id IS NOT NULL THEN c.person_role_id ELSE 0 END) AS avg_role_id,
    MAX(CASE WHEN mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mo.info END) AS budget_info,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Year Unknown' 
        WHEN mh.production_year < 2000 THEN 'Classic' 
        ELSE 'Modern' 
    END AS era
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    movie_info mo ON mh.movie_id = mo.movie_id
GROUP BY 
    mh.depth, mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT kw.id) > 5 
ORDER BY 
    mh.depth ASC, COUNT(DISTINCT c.person_id) DESC, mh.production_year DESC
LIMIT 100;
