WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        1 AS level,
        ARRAY[m.id] AS chain
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA' AND
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.linked_movie_id,
        lt.title,
        mc.level + 1,
        mc.chain || m.linked_movie_id
    FROM 
        movie_link m
    JOIN 
        movie_chain mc ON mc.movie_id = m.movie_id
    JOIN 
        aka_title lt ON m.linked_movie_id = lt.id
    WHERE 
        lt.production_year >= 2000 AND
        NOT m.linked_movie_id = ANY(mc.chain)
)

SELECT 
    m.movie_id,
    m.title,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(CASE 
        WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
        THEN CAST(pi.info AS FLOAT) 
        ELSE NULL 
    END) AS average_rating,
    MAX(CASE 
        WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
        THEN CAST(pi.info AS INTEGER) 
        ELSE NULL 
    END) AS max_budget
FROM 
    movie_chain m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    person_info pi ON c.person_id = pi.person_id
GROUP BY 
    m.movie_id, m.title
HAVING 
    COUNT(DISTINCT c.person_id) > 5 AND
    average_rating IS NOT NULL
ORDER BY 
    average_rating DESC, max_budget DESC
LIMIT 10;
