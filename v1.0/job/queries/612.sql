
WITH RankedTitles AS (
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
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        a.actor_count,
        m.companies,
        m.company_count
    FROM 
        RankedTitles r
    LEFT JOIN 
        ActorCounts a ON r.title_id = a.movie_id
    LEFT JOIN 
        MovieCompanies m ON r.title_id = m.movie_id
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.actor_count, 0) AS actor_count,
    COALESCE(f.company_count, 0) AS company_count,
    CASE 
        WHEN f.actor_count IS NULL THEN 'No actors'
        WHEN f.actor_count < 3 THEN 'Few actors'
        ELSE 'Many actors' 
    END AS actor_status,
    CASE 
        WHEN f.company_count IS NULL OR f.company_count = 0 THEN 'No companies'
        ELSE f.companies
    END AS production_companies
FROM 
    FilteredMovies f
WHERE 
    f.production_year > 2000
ORDER BY 
    f.production_year DESC, f.title ASC;
