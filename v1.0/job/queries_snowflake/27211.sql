WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY LENGTH(t.title)) AS title_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        t.production_year > 2000
),
ActorMovies AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name,
        COUNT(*) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
    HAVING 
        COUNT(*) > 2
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id, cn.name
)

SELECT 
    rt.title,
    rt.production_year,
    am.actor_name,
    cm.company_name,
    rt.keyword,
    rt.title_rank
FROM 
    RankedTitles rt
JOIN 
    ActorMovies am ON rt.title_id = am.movie_id
JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, 
    LENGTH(am.actor_name), 
    cm.company_count DESC;
