WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY tk.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        t.production_year >= 2000
), QualifiedActors AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS actor_name,
        ci.movie_id,
        c.role AS role_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS rank_within_movie
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type c ON ci.person_role_id = c.id
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    qa.actor_name,
    qa.role_name,
    mc.companies
FROM 
    RankedTitles rt
JOIN 
    QualifiedActors qa ON rt.title_id = qa.movie_id
JOIN 
    MovieCompanies mc ON rt.title_id = mc.movie_id
WHERE 
    qa.rank_within_movie <= 5  
ORDER BY 
    rt.production_year DESC, 
    rt.title, 
    qa.actor_name;