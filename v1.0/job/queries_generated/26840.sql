WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        a.md5sum AS actor_md5,
        c.role_id,
        p.info AS actor_biography,
        k.keyword AS movie_keyword
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN person_info p ON a.person_id = p.person_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year BETWEEN 2000 AND 2020
      AND k.keyword LIKE 'Action%'
),
actor_statistics AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movies_count,
        STRING_AGG(DISTINCT movie_title, ', ') AS movies_list,
        COUNT(DISTINCT actor_md5) AS unique_ids
    FROM movie_data
    GROUP BY actor_name
)
SELECT 
    actor_name,
    movies_count,
    movies_list,
    unique_ids,
    CASE 
        WHEN movies_count > 10 THEN 'Prolific Actor'
        WHEN movies_count BETWEEN 5 AND 10 THEN 'Moderate Actor'
        ELSE 'Newcomer Actor'
    END AS actor_classification
FROM actor_statistics
ORDER BY movies_count DESC;
