WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        COUNT(DISTINCT ci.person_id) AS number_of_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
),
MovieCompanies AS (
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
)
SELECT 
    tm.title, 
    tm.production_year, 
    cd.actor_name, 
    cd.number_of_actors, 
    mc.company_name, 
    mc.company_type
FROM 
    TopMovies tm
JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
JOIN 
    MovieCompanies mc ON tm.movie_id = mc.movie_id
ORDER BY 
    tm.production_year DESC, cd.number_of_actors DESC, mc.company_name;
