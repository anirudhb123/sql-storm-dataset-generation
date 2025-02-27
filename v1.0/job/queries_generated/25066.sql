WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
),
affected_companies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code = 'USA'
),
top_actors AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
)
SELECT 
    rt.title,
    rt.production_year,
    rt.kind,
    ac.company_name,
    ac.company_type,
    ta.actor_name
FROM 
    ranked_titles rt
JOIN 
    affected_companies ac ON rt.title_id = ac.movie_id
JOIN 
    top_actors ta ON rt.title_id = ta.movie_id
WHERE 
    rt.title_rank <= 5
    AND ta.actor_rank = 1
ORDER BY 
    rt.production_year DESC, 
    rt.title;

This query benchmarks string processing by aggregating and retrieving top movie titles, company details, and leading actors across different tables while applying sorting and ranking mechanisms. It emphasizes the use of window functions alongside joins and filtering conditions.
