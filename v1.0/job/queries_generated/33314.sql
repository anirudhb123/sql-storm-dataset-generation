WITH RECURSIVE actor_hierarchy AS (
    SELECT a.id AS actor_id, a.person_id, ak.name AS actor_name, 
           CAST(0 AS INTEGER) AS level 
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title at ON ci.movie_id = at.movie_id
    WHERE ak.name IS NOT NULL
    
    UNION ALL
    
    SELECT ah.actor_id, ci.person_id, ak.name, ah.level + 1
    FROM actor_hierarchy ah
    JOIN cast_info ci ON ah.actor_id = ci.id
    JOIN aka_name ak ON ci.person_id = ak.person_id
)
SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT ah.actor_id) AS actor_count,
    LISTAGG(DISTINCT ah.actor_name, ', ') WITHIN GROUP (ORDER BY ah.actor_name) AS actor_names,
    mr.production_year,
    dt.kind AS movie_genre,
    CASE 
        WHEN COUNT(DISTINCT ah.actor_id) IS NULL THEN 'No actors'
        ELSE 'Actors present'
    END AS actor_status
FROM title t
JOIN movie_keyword mk ON t.id = mk.movie_id
JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration')
LEFT JOIN actor_hierarchy ah ON ah.actor_id = CAST(t.id AS INTEGER)
LEFT JOIN aka_title at ON t.id = at.movie_id
LEFT JOIN kind_type dt ON at.kind_id = dt.id
LEFT JOIN movie_companies mc ON t.id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN complete_cast cc ON cc.movie_id = t.id
WHERE t.production_year >= 2000
AND k.keyword LIKE '%drama%'
GROUP BY t.title, mr.production_year, dt.kind
HAVING COUNT(DISTINCT ah.actor_id) > 0
ORDER BY actor_count DESC, t.title;
