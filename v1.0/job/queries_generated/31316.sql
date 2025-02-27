WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    a.id AS aka_id,
    a.name AS alias_name,
    t.title AS movie_title,
    t.production_year,
    t.kind_id,
    c.kind AS cast_type,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.id) AS alias_rank,
    COUNT(DISTINCT mc.company_id) OVER (PARTITION BY t.id) AS total_companies,
    COALESCE(NULLIF(ki.keyword, ''), '(No Keywords)') AS keyword_used,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = t.id AND mi.note IS NULL) AS null_info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id 
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
    AND (t.production_year BETWEEN 2000 AND 2023)
    AND a.name_pcode_nf IS NOT NULL
    AND a.md5sum IS NOT NULL
    AND (SELECT COUNT(*) 
         FROM complete_cast cc 
         WHERE cc.movie_id = t.id) > 5
ORDER BY 
    t.production_year DESC, 
    alias_rank;
