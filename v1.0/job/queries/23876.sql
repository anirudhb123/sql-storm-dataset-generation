WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

cast_details AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),

company_movies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(co.name, ', ') AS companies_produced
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    GROUP BY 
        m.movie_id
),

title_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    t.title,
    t.production_year,
    c.actor_name,
    c.role_name,
    co.companies_produced,
    tk.keywords,
    MAX(CASE WHEN c.cast_rank = 1 THEN c.actor_name END) AS lead_actor,
    COUNT(DISTINCT c.cast_id) AS total_cast,
    COUNT(DISTINCT tk.keywords) AS total_keywords,
    CASE 
        WHEN c.role_name IS NULL THEN 'No Role Assigned'
        ELSE 'Role Exists'
    END AS role_status
FROM 
    ranked_titles t
LEFT JOIN 
    cast_details c ON t.title_id = c.movie_id
LEFT JOIN 
    company_movies co ON t.title_id = co.movie_id
LEFT JOIN 
    title_keywords tk ON t.title_id = tk.movie_id
WHERE 
    t.title_rank <= 5
AND 
    (c.role_name IS NOT NULL OR co.companies_produced IS NOT NULL)
GROUP BY 
    t.title, t.production_year, c.actor_name, c.role_name, co.companies_produced, tk.keywords
ORDER BY 
    t.production_year DESC, t.title;
