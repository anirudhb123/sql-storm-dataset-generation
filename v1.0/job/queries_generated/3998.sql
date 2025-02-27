WITH ranked_titles AS (
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
actor_title AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.id, a.name, t.title, t.production_year
),
company_movie AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, c.name, ct.kind
)
SELECT 
    at.actor_id,
    at.actor_name,
    at.movie_title,
    at.production_year,
    ct.company_name,
    ct.company_type,
    COALESCE(rt.title_rank, 0) AS title_rank,
    at.movie_count,
    ct.company_count
FROM 
    actor_title at
LEFT JOIN 
    company_movie ct ON at.movie_title = ct.movie_id
LEFT JOIN 
    ranked_titles rt ON at.production_year = rt.production_year
WHERE 
    (at.movie_count > 5 OR ct.company_count < 3)
    AND (at.actor_name IS NOT NULL AND at.actor_name <> '')
ORDER BY 
    at.actor_name ASC, 
    at.production_year DESC;
