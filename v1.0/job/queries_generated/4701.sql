WITH RankedTitles AS (
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
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        RankedTitles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ci.person_id
),
CompanyMovieStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
TopActors AS (
    SELECT 
        an.name, 
        amc.movie_count
    FROM 
        aka_name an
    JOIN 
        ActorMovieCounts amc ON an.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5
),
MovieDetails AS (
    SELECT 
        rt.title,
        rt.production_year,
        COALESCE(cms.company_count, 0) AS company_count,
        COALESCE(cms.noted_count, 0) AS noted_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompanyMovieStats cms ON rt.title_id = cms.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.noted_count,
    ta.name AS top_actor_name
FROM 
    MovieDetails md
LEFT JOIN 
    TopActors ta ON ta.movie_count > 0
WHERE 
    md.company_count > 3
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC;
