
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    COALESCE(STRING_AGG(tc.actor_name ORDER BY tc.actor_rank), 'No cast available') AS top_actors
FROM 
    RankedTitles r
LEFT JOIN 
    TopCast tc ON r.title_id = tc.movie_id
WHERE 
    r.title_rank <= 3
GROUP BY 
    r.title_id, r.title, r.production_year
ORDER BY 
    r.production_year DESC, r.title;
