
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
actor_average_scores AS (
    SELECT 
        c.person_id,
        AVG(CAST(mi.info AS numeric)) AS avg_score
    FROM 
        cast_info c
    JOIN 
        movie_info mi ON c.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'score')
    GROUP BY 
        c.person_id
),
actor_titles AS (
    SELECT 
        ak.name AS actor_name,
        rt.title AS title_name,
        rt.production_year,
        ac.avg_score
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        ranked_titles rt ON ci.movie_id = rt.title_id
    LEFT JOIN 
        actor_average_scores ac ON ak.person_id = ac.person_id
)
SELECT 
    at.actor_name,
    at.title_name,
    at.production_year,
    COALESCE(at.avg_score, 0) AS average_score
FROM 
    actor_titles at
WHERE 
    at.avg_score IS NOT NULL 
    OR at.production_year < 2010
ORDER BY 
    at.production_year DESC, 
    at.actor_name ASC;
