
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
), 
actor_movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        ranked_titles rt ON c.movie_id = rt.title_id
    GROUP BY 
        c.person_id
),
actor_names AS (
    SELECT 
        a.person_id,
        LISTAGG(a.name, ', ') AS names
    FROM 
        aka_name a
    GROUP BY 
        a.person_id
)
SELECT 
    am.person_id,
    an.names,
    am.movie_count,
    rt.title,
    rt.production_year
FROM 
    actor_movie_counts am
JOIN 
    actor_names an ON am.person_id = an.person_id
LEFT JOIN 
    ranked_titles rt ON am.movie_count = rt.title_rank
WHERE 
    am.movie_count > 3
ORDER BY 
    am.movie_count DESC, 
    rt.production_year DESC NULLS LAST;
