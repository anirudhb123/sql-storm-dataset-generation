WITH movie_data AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        a.name AS actor_name, 
        a.surname_pcode, 
        p.info AS person_info, 
        k.keyword AS movie_keyword
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN person_info p ON a.person_id = p.person_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
      AND p.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
)
SELECT 
    md.movie_id, 
    md.title, 
    md.production_year, 
    COUNT(DISTINCT md.actor_name) AS actor_count, 
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
FROM movie_data md
GROUP BY md.movie_id, md.title, md.production_year
HAVING COUNT(DISTINCT md.actor_name) > 5
ORDER BY md.production_year DESC, actor_count DESC;
