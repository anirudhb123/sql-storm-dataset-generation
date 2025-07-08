WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
frequent_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 2
),
top_companies AS (
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
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
)
SELECT 
    rt.title AS movie_title,
    rt.production_year,
    tk.keyword,
    tc.company_name,
    tc.company_type,
    cd.actor_name,
    cd.role_name
FROM 
    ranked_titles rt
LEFT JOIN 
    frequent_keywords tk ON rt.title_id = tk.movie_id
LEFT JOIN 
    top_companies tc ON rt.title_id = tc.movie_id
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, LENGTH(rt.title) DESC;
