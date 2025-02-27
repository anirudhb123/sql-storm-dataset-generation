WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IN (SELECT id FROM aka_title WHERE production_year > 2000)
    
    UNION ALL
    
    SELECT 
        c.person_id,
        a.name,
        level + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN actor_hierarchy ah ON c.movie_id = ah.movie_id
    WHERE level < 3
)
SELECT 
    t.title,
    a.actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(mo.rating) AS average_rating,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    SUM(CASE 
            WHEN m.production_year IS NULL THEN 0 
            ELSE 1 
        END) AS year_present,
    CASE 
        WHEN a.actor_name IS NULL THEN 'Unknown Actor'
        ELSE a.actor_name
    END AS display_actor
FROM aka_title t
LEFT JOIN complete_cast cc ON t.id = cc.movie_id
LEFT JOIN actor_hierarchy ah ON cc.subject_id = ah.person_id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN movie_info mi ON t.id = mi.movie_id
LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN (
    SELECT movie_id, 
           AVG(info::FLOAT) AS rating 
    FROM movie_info 
    WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
    GROUP BY movie_id
) mo ON t.id = mo.movie_id
WHERE t.production_year IS NOT NULL
GROUP BY t.title, a.actor_name
HAVING COUNT(DISTINCT mc.company_id) > 1
ORDER BY average_rating DESC NULLS LAST, display_actor ASC;

