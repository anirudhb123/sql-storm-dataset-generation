WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
top_companies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
selected_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    tt.title AS movie_title,
    tt.production_year,
    tc.company_name,
    tc.company_type,
    sc.actor_name,
    sc.role_name
FROM 
    ranked_titles tt
JOIN 
    top_companies tc ON tt.title_id = tc.movie_id AND tc.company_rank = 1
JOIN 
    selected_cast sc ON tt.title_id = sc.movie_id
WHERE 
    tt.year_rank <= 5 -- Retrieve only the top 5 recent productions
ORDER BY 
    tt.production_year DESC, tc.company_name;

This SQL query benchmarks string processing by generating a list of recent movie titles along with their top associated companies and lead actors. It uses Common Table Expressions (CTEs) to rank productions by year, select top companies associated with each movie, and pull the top-ranked cast members, creating an elaborate join of the data. The results are ordered by the production year and company name to maintain a structured output.
