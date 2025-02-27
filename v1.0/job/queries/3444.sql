
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        MAX(a.name) AS lead_actor,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_involved
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mco.companies_involved, 'None') AS companies_involved,
    COALESCE(mc.lead_actor, 'Unknown') AS lead_actor,
    COALESCE(mc.total_cast, 0) AS total_cast,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5 Movies of Year'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieCompanies mco ON rm.movie_id = mco.movie_id
WHERE 
    rm.production_year >= 2000
    AND EXISTS (SELECT 1 
                FROM movie_info mi 
                WHERE mi.movie_id = rm.movie_id 
                AND mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Box Office', 'Budget')))
ORDER BY 
    rm.production_year DESC, 
    rm.title;
