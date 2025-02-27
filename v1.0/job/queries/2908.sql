WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
), actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COALESCE(ci.note, 'No Role') AS role,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name, ci.note
), movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title AS movie_title,
    rt.production_year,
    ai.name AS actor_name,
    ai.role,
    ai.movie_count,
    mkc.keywords
FROM 
    ranked_titles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    actor_info ai ON a.id = ai.actor_id
LEFT JOIN 
    movie_keyword_counts mkc ON rt.title_id = mkc.movie_id
WHERE 
    rt.title_rank <= 5
  AND 
    rt.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rt.production_year DESC, 
    ai.movie_count DESC;
