WITH RECURSIVE actor_hierarchy AS (
    SELECT p.id AS person_id, 
           a.name, 
           1 AS depth
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    JOIN aka_title at ON t.id = at.movie_id
    JOIN name n ON a.person_id = n.imdb_id
    WHERE n.gender = 'F' AND t.production_year > 1990

    UNION ALL

    SELECT ah.person_id, 
           CONCAT(ah.name, ' (Related)'), 
           ah.depth + 1
    FROM actor_hierarchy ah
    JOIN cast_info c2 ON ah.person_id = c2.person_id
    JOIN title t2 ON c2.movie_id = t2.id
    WHERE t2.production_year < EXTRACT(YEAR FROM CURRENT_DATE) - 10
             AND t2.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),

movie_info_summary AS (
    SELECT m.id AS movie_id,
           MAX(m.title) AS latest_title,
           STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
           COUNT(DISTINCT c.person_id) AS total_cast
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info c ON m.id = c.movie_id
    GROUP BY m.id
),

null_logic_handling AS (
    SELECT mi.movie_id,
           mi.latest_title,
           COALESCE(mi.keywords, 'No Keywords') AS keywords,
           CASE WHEN mi.total_cast > 2 THEN 'Has Many Cast'
                WHEN mi.total_cast = 0 THEN 'No Cast Info'
                ELSE 'Limited Cast Info' END AS cast_info_status
    FROM movie_info_summary mi
)

SELECT ah.name AS actor_name,
       ml.movie_id,
       ml.latest_title,
       nl.keywords,
       nl.cast_info_status
FROM actor_hierarchy ah
FULL OUTER JOIN null_logic_handling nl ON ah.person_id = nl.movie_id
WHERE ah.depth < 5 OR nl.keywords <> 'No Keywords'
ORDER BY ah.depth, nl.cast_info_status DESC, nl.latest_title;
