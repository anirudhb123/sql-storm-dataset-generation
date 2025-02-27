WITH ranked_titles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_count AS (
    SELECT 
        ka.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    GROUP BY 
        ka.person_id
),
movie_genre AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
completed_movies AS (
    SELECT 
        m.movie_id,
        m.subject_id,
        m.status_id,
        rt.movie_title,
        rt.production_year,
        mg.genres
    FROM 
        complete_cast m
    JOIN 
        ranked_titles rt ON m.movie_id = rt.movie_id
    LEFT JOIN 
        movie_genre mg ON m.movie_id = mg.movie_id
)
SELECT 
    ka.name AS actor_name,
    ac.movie_count,
    cm.movie_title,
    cm.production_year,
    cm.genres
FROM 
    aka_name ka
JOIN 
    actor_count ac ON ka.person_id = ac.person_id
JOIN 
    cast_info ci ON ka.person_id = ci.person_id
JOIN 
    completed_movies cm ON ci.movie_id = cm.movie_id
WHERE 
    ac.movie_count > 5
ORDER BY 
    ac.movie_count DESC,
    cm.production_year DESC, cm.movie_title;
