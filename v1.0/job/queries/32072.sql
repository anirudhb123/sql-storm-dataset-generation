WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        h.depth + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy h ON h.movie_id = m.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    AVG(CASE 
        WHEN ci.note IS NOT NULL THEN 1 
        ELSE 0 
    END) AS actor_contribution,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS movie_rank
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
WHERE 
    t.production_year >= 2000
AND 
    (LOWER(a.name) LIKE '%john%' OR LOWER(a.name) LIKE '%smith%')
AND 
    EXISTS (
        SELECT 1
        FROM complete_cast cc
        WHERE cc.movie_id = t.id AND cc.subject_id = ci.person_id
    )
AND 
    NOT EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = t.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'disqualified')
    )
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    actor_name, movie_rank
LIMIT 100;
