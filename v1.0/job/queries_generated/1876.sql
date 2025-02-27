WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_details AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
),
recent_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        MAX(t.production_year) AS latest_year
    FROM 
        title t
    WHERE 
        t.production_year >= (SELECT MAX(production_year) - 5 FROM title)
    GROUP BY 
        t.id, t.title
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.actor_count,
    ad.actor_name,
    ad.actor_rank,
    CASE 
        WHEN rm.actor_count IS NULL THEN 'No actors found'
        ELSE 'Actors available'
    END AS actor_status
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_details ad ON rm.title = ad.movie_title AND rm.production_year = ad.production_year
LEFT JOIN 
    recent_movies rwm ON rm.title = rwm.movie_title
WHERE 
    rm.rank <= 10 
    AND (rwm.movie_id IS NOT NULL OR rm.actor_count > 5)
ORDER BY 
    rm.actor_count DESC, rm.production_year DESC;
