WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
actor_movies AS (
    SELECT 
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        COUNT(c.movie_id) OVER (PARTITION BY a.person_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title at ON c.movie_id = at.movie_id
), 
filtered_movies AS (
    SELECT 
        DISTINCT am.actor_name,
        am.movie_title,
        am.production_year,
        am.movie_count
    FROM 
        actor_movies am
    WHERE 
        am.movie_count > 5
),
companies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
)
SELECT 
    f.actor_name,
    f.movie_title,
    f.production_year,
    COALESCE(c.company_name, 'Independent') AS production_company,
    COUNT(DISTINCT c.company_name) AS num_companies
FROM 
    filtered_movies f
LEFT JOIN 
    companies c ON f.movie_title = c.movie_id
GROUP BY 
    f.actor_name, f.movie_title, f.production_year, production_company
HAVING 
    COUNT(DISTINCT c.company_name) >= 1
ORDER BY 
    f.production_year DESC, f.actor_name;
