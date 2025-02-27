WITH RECURSIVE actor_movie AS (
    SELECT 
        c.person_id,
        c.movie_id,
        1 AS depth
    FROM 
        cast_info c
    WHERE 
        c.role_id = (SELECT id FROM role_type WHERE role = 'actor')
    
    UNION ALL
    
    SELECT 
        c.person_id,
        c.movie_id,
        am.depth + 1
    FROM 
        cast_info c
    JOIN 
        actor_movie am ON c.movie_id = am.movie_id
    WHERE 
        c.role_id IN (SELECT id FROM role_type WHERE role IN ('director', 'producer')) 
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT am.person_id) AS coactors_count,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    STRING_AGG(DISTINCT c.note, ', ') AS role_notes,
    MAX(COALESCE(special_keywords, 'No Keywords')) AS special_keywords_list
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS special_keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            k.keyword ILIKE '%special%'
        GROUP BY 
            mk.movie_id
    ) sk ON sk.movie_id = t.id
LEFT JOIN 
    actor_movie am ON a.person_id = am.person_id
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT am.person_id) > 1
ORDER BY 
    t.production_year DESC,
    coactors_count DESC;
