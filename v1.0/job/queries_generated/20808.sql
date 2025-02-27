WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        p.id AS person_id, 
        a.name AS actor_name,
        0 AS depth
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    WHERE t.production_year >= 2000 -- Focus on movies after 2000
      AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        p.id AS person_id, 
        a.name AS actor_name,
        ah.depth + 1
    FROM ActorHierarchy ah
    JOIN cast_info ci ON ah.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    JOIN aka_name a ON a.person_id = ci.person_id
    WHERE t.production_year < 2000
)

SELECT 
    r.actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT ci.movie_id) AS number_of_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(t.production_year) OVER (PARTITION BY r.actor_name) AS latest_movie_year,
    CASE 
        WHEN COUNT(DISTINCT ci.movie_id) > 5 THEN 'Prolific Actor' 
        ELSE 'Regular Actor' 
    END AS actor_status
FROM ActorHierarchy r
JOIN cast_info ci ON r.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN keyword k ON mk.keyword_id = k.id
GROUP BY r.actor_name, t.title, t.production_year
HAVING COUNT(DISTINCT ci.movie_id) > 2 AND 
       MAX(t.production_year) = (SELECT MAX(t2.production_year) 
                                 FROM title t2 
                                 JOIN cast_info ci2 ON t2.id = ci2.movie_id 
                                 WHERE ci2.person_id = r.person_id)
ORDER BY latest_movie_year DESC, actor_name ASC;

-- Additionally, performing a complex join and including NULL checks for semantic exploration
SELECT 
    cn.name AS company_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.movie_id) AS films_produced,
    MAX(m.production_year) AS latest_release_year
FROM company_name cn
LEFT JOIN movie_companies mc ON cn.id = mc.company_id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN aka_title at ON mc.movie_id = at.movie_id
LEFT JOIN title m ON at.movie_id = m.id
WHERE cn.country_code IS NOT NULL 
  AND (ct.kind IS NULL OR ct.kind <> 'Distributor')
GROUP BY cn.name, ct.kind
HAVING COUNT(DISTINCT mc.movie_id) > 1
   OR MAX(m.production_year) IS NULL
ORDER BY films_produced DESC, company_name;

-- Using a subquery with a complicated set operation to find overlapping genre interest
SELECT 
    a.actor_name,
    STRING_AGG(DISTINCT ako.title, ', ') AS shared_movies,
    COUNT(DISTINCT ko.keyword) AS shared_genres
FROM (
    SELECT DISTINCT a.name AS actor_name, t.id AS title_id
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
) a
JOIN movie_keyword mk ON mk.movie_id = a.title_id
JOIN keyword ko ON ko.id = mk.keyword_id
JOIN aka_title ako ON ako.id = a.title_id
GROUP BY a.actor_name
HAVING shared_genres > 2
ORDER BY shared_genres DESC, a.actor_name;
