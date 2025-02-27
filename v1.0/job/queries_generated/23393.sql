WITH RECURSIVE parent_movie_cte AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        p.name AS person_name,
        1 AS level
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        mm.id,
        mm.title,
        mm.title AS person_name,
        pc.level + 1
    FROM 
        parent_movie_cte pc
    JOIN 
        movie_link ml ON pc.movie_id = ml.movie_id
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
)

SELECT 
    pm.movie_id,
    pm.movie_title,
    LISTAGG(pm.person_name, ', ') WITHIN GROUP (ORDER BY pm.person_name) AS cast_list,
    COUNT(DISTINCT mci.movie_id) AS num_company_movies,
    MAX(CASE WHEN kc.keyword IS NOT NULL THEN kc.keyword ELSE 'No Keywords' END) AS first_keyword,
    SUM(CASE WHEN ci.person_role_id IS NULL THEN 0 ELSE 1 END) AS total_roles,
    AVG(COALESCE(mk.id, 0)) FILTER (WHERE mk.id IS NOT NULL) AS avg_keyword_id
FROM 
    parent_movie_cte pm
LEFT JOIN 
    movie_companies mc ON pm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
LEFT JOIN 
    movie_keyword mk ON pm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    cast_info ci ON pm.movie_id = ci.movie_id
WHERE 
    pm.level < 3 
    AND pm.movie_title IS NOT NULL
GROUP BY 
    pm.movie_id, pm.movie_title
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    num_company_movies DESC, movie_title ASC;
