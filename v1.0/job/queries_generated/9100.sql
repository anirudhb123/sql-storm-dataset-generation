WITH RankedTitles AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.kind_id = 1
), ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        COUNT(*) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name, c.movie_id
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
), MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ad.actor_name,
    ad.role_count,
    mc.company_names,
    mw.keywords
FROM 
    RankedTitles rt
JOIN 
    ActorDetails ad ON rt.id = ad.movie_id
JOIN 
    MovieCompanies mc ON rt.id = mc.movie_id
JOIN 
    MoviesWithKeywords mw ON rt.id = mw.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, ad.role_count DESC;
