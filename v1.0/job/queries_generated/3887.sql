WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        r.title,
        r.production_year
    FROM 
        RankedMovies r
    WHERE 
        r.year_rank <= 10
),
CastDetails AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) as total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    cd.total_cast,
    cd.actor_names,
    mc.company_names,
    mc.company_types
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.title = cd.movie_id
LEFT JOIN 
    MovieCompanies mc ON tm.title = mc.movie_id
WHERE 
    (cd.total_cast > 5 OR cd.total_cast IS NULL)
ORDER BY 
    tm.production_year DESC,
    cd.total_cast DESC;
