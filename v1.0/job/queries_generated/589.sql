WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY t.kind_id DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        kind_type t ON m.kind_id = t.id
    WHERE 
        m.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(ac.movie_count, 0) AS actor_count,
    fc.company_name,
    fc.company_type
FROM 
    RankedMovies r
LEFT JOIN 
    ActorMovieCount ac ON ac.person_id IN (
        SELECT 
            DISTINCT ci.person_id 
        FROM 
            cast_info ci 
        WHERE 
            ci.movie_id = r.movie_id
    )
LEFT JOIN 
    FilteredCompanies fc ON fc.movie_id = r.movie_id
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, 
    r.title ASC;
