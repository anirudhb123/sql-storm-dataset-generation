WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    JOIN 
        role_type r ON ca.role_id = r.id
    WHERE 
        r.role ILIKE '%lead%'
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorCounts AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        cast_info ca
    JOIN 
        aka_title t ON ca.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        ca.person_id
),
MovieCompanies AS (
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
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ac.person_id,
    ac.movie_count,
    mc.company_name,
    mc.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorCounts ac ON ac.movie_count = (SELECT MAX(movie_count) FROM ActorCounts)
LEFT JOIN 
    MovieCompanies mc ON mc.movie_id = rm.movie_id
WHERE 
    rm.rank <= 5 
    AND (mc.company_type IS NULL OR mc.company_type <> 'Distributor')
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
