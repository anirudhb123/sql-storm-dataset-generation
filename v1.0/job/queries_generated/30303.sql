WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        mk.linked_movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link mk
    JOIN 
        title m ON mk.movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mk.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    AVG(mo.info_length) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS rank,
    CASE 
        WHEN a.surname_pcode IS NULL THEN 'No Code' 
        ELSE 'Has Code' 
    END AS surname_code_status
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        LENGTH(info) AS info_length
    FROM 
        movie_info
    WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
) mo ON t.id = mo.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND (cn.country_code = 'USA' OR cn.country_code IS NULL)
GROUP BY 
    a.name, t.id, t.production_year, a.surname_pcode
ORDER BY 
    avg_info_length DESC, keyword_count DESC;
