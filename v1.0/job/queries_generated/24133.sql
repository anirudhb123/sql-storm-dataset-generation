WITH RECURSIVE title_hierarchy AS (
    SELECT t.id, t.title, t.production_year, t.kind_id, 
           CASE 
               WHEN t.season_nr IS NOT NULL THEN 'Season ' || t.season_nr || ' Episode ' || t.episode_nr 
               ELSE 'Feature Film' 
           END AS title_classification,
           1 AS depth
    FROM title t
    WHERE t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT t.id, t.title, t.production_year, t.kind_id, 
           'Episode of ' || pt.title || ' (Season ' || t.season_nr || ')' AS title_classification,
           depth + 1
    FROM title t
    JOIN title pt ON t.episode_of_id = pt.id
)
SELECT 
    ak.name AS actor_name,
    tt.title_classification AS movie_title,
    tt.production_year,
    ci.nr_order AS role_order,
    GROUP_CONCAT(DISTINCT i.info ORDER BY i.info_type_id) AS additional_info,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY tt.production_year DESC) AS role_rank
FROM aka_name ak
JOIN cast_info ci ON ak.person_id = ci.person_id
JOIN title_hierarchy tt ON ci.movie_id = tt.id
LEFT JOIN movie_info mi ON tt.id = mi.movie_id
LEFT JOIN info_type it ON mi.info_type_id = it.id
LEFT JOIN movie_keyword mk ON tt.id = mk.movie_id
GROUP BY ak.name, tt.title_classification, tt.production_year, ci.nr_order
HAVING 
    COUNT(DISTINCT mk.keyword) > 0 
    AND tt.production_year >= COALESCE((
        SELECT MAX(production_year) 
        FROM title
        WHERE kind_id = ANY(SELECT kind_id FROM kind_type WHERE kind = 'Documentary')
    ), 1900) 
    AND ak.md5sum IS NOT NULL 
ORDER BY role_rank, tt.production_year DESC;
