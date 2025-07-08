WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        RANK() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
), 
ActorMovies AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        c.nr_order 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
), 
CompanyMovies AS (
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
), 
KeywordMovies AS (
    SELECT 
        mk.movie_id, 
        k.keyword 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    rt.title, 
    rt.production_year, 
    am.actor_name, 
    cm.company_name, 
    cm.company_type, 
    km.keyword
FROM 
    RankedTitles rt
JOIN 
    ActorMovies am ON rt.title_id = am.movie_id
JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    KeywordMovies km ON rt.title_id = km.movie_id
WHERE 
    rt.title_rank <= 5 
ORDER BY 
    rt.production_year DESC, rt.title ASC;
