
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m 
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mv.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link mv 
    JOIN 
        aka_title a ON mv.linked_movie_id = a.id
    JOIN 
        movie_hierarchy mh ON mv.movie_id = mh.movie_id
)

SELECT 
    ah.name,
    mt.title,
    mt.production_year,
    COUNT(DISTINCT c.role_id) AS role_count,
    AVG(COALESCE(mi.info_type_id, 0)) AS avg_info_type_id,
    LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ah.person_id ORDER BY ah.name) AS person_rank,
    CASE 
        WHEN cc.kind IS NOT NULL THEN cc.kind
        ELSE 'Unknown' 
    END AS company_type
FROM 
    aka_name ah
JOIN 
    cast_info c ON ah.person_id = c.person_id
JOIN 
    aka_title mt ON c.movie_id = mt.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_type cc ON mc.company_type_id = cc.id
WHERE 
    mt.production_year >= 2000
    AND (ah.name IS NOT NULL AND ah.name <> '')
    AND (mt.title ILIKE '%action%' OR mt.title ILIKE '%drama%')
GROUP BY 
    ah.person_id, ah.name, mt.title, mt.production_year, cc.kind
HAVING 
    COUNT(DISTINCT c.role_id) > 2
ORDER BY 
    mt.production_year DESC, person_rank;
