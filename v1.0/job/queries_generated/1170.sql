WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rnk
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rnk <= 5 -- Top 5 movies per year
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
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
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cd.actor_count, 0) AS actor_count,
    COALESCE(cd.actor_names, 'No Actors') AS actor_names,
    COALESCE(mco.company_count, 0) AS company_count,
    COALESCE(mco.company_names, 'No Companies') AS company_names
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompanies mco ON tm.movie_id = mco.movie_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, tm.title;
