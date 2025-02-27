WITH RankedTitles AS (
    SELECT 
        title.id AS title_id, 
        title.title, 
        title.production_year, 
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rank
    FROM 
        title
    WHERE 
        title.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
), 
ActorMovies AS (
    SELECT 
        cast_info.movie_id, 
        COUNT(DISTINCT cast_info.person_id) AS actor_count
    FROM 
        cast_info
    GROUP BY 
        cast_info.movie_id
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rt.title_id, 
    rt.title, 
    rt.production_year,
    am.actor_count,
    COALESCE(cd.company_count, 0) AS company_count,
    CASE 
        WHEN rt.production_year < 2000 THEN 'Classic'
        WHEN rt.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorMovies am ON rt.title_id = am.movie_id
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
WHERE 
    (am.actor_count IS NULL OR am.actor_count > 3)
    AND rt.rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
