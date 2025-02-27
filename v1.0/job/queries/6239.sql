WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorPopularities AS (
    SELECT 
        a.person_id, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        ap.person_id
    FROM 
        ActorPopularities ap
    ORDER BY 
        ap.movie_count DESC 
    LIMIT 10
),
MovieCompaniesInfo AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.id
)
SELECT 
    rt.title,
    rt.production_year,
    a.name,
    mci.companies
FROM 
    RankedTitles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    TopActors ta ON a.person_id = ta.person_id
JOIN 
    MovieCompaniesInfo mci ON rt.title_id = mci.movie_id
ORDER BY 
    rt.production_year DESC, 
    rt.title;
