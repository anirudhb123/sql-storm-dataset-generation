WITH RECURSIVE movie_relations AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        c.person_id AS actor_id,
        a.name AS actor_name,
        1 AS depth
    FROM title m
    JOIN cast_info c ON c.movie_id = m.id
    JOIN aka_name a ON a.person_id = c.person_id
    WHERE m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id,
        m.title,
        c.person_id,
        a.name,
        depth + 1
    FROM movie_relations mr
    JOIN movie_link ml ON ml.movie_id = mr.movie_id
    JOIN title m ON m.id = ml.linked_movie_id
    JOIN cast_info c ON c.movie_id = m.id
    JOIN aka_name a ON a.person_id = c.person_id
    WHERE mr.depth < 3  -- Limit to 3 levels of movies
),
distinct_keywords AS (
    SELECT DISTINCT 
        k.keyword 
    FROM movie_keyword mk
    JOIN keyword k ON k.id = mk.keyword_id
    WHERE k.keyword IS NOT NULL
    AND LENGTH(k.keyword) > 5
),
grouped_cast AS (
    SELECT 
        c.role_id,
        COUNT(DISTINCT ci.person_id) AS actor_count 
    FROM cast_info ci
    JOIN role_type c ON c.id = ci.role_id
    GROUP BY c.role_id
),
movie_scores AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(SUM(CASE 
            WHEN m.production_year < 2010 THEN 1
            ELSE 2 
        END), 0) AS score
    FROM title m
    GROUP BY m.id
)

SELECT 
    mr.movie_id,
    mr.movie_title,
    mr.actor_name,
    COUNT(DISTINCT dk.keyword) AS keyword_count,
    AVG(ms.score) AS avg_movie_score,
    MAX(g.actor_count) FILTER (WHERE g.actor_count > 5) AS popular_role_count,
    SUM(CASE 
        WHEN mr.depth >= 3 THEN 1
        ELSE 0 
    END) AS linked_movie_count
FROM movie_relations mr
LEFT JOIN distinct_keywords dk ON dk.keyword IN (
    SELECT keyword 
    FROM movie_keyword mk 
    WHERE mk.movie_id = mr.movie_id
)
LEFT JOIN movie_scores ms ON ms.movie_id = mr.movie_id
JOIN grouped_cast g ON g.role_id IN (
    SELECT ca.role_id 
    FROM cast_info ca 
    WHERE ca.movie_id = mr.movie_id
)
GROUP BY mr.movie_id, mr.movie_title, mr.actor_name
HAVING COUNT(DISTINCT dk.keyword) > 5 
AND AVG(ms.score) > 1
ORDER BY avg_movie_score DESC, linked_movie_count DESC;

