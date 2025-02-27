WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS year_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COALESCE(rt.role, 'Unknown Role') AS role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    cd.actor_name,
    cd.role,
    mci.companies,
    mci.company_types
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON tm.movie_id = mci.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
