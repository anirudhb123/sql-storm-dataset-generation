WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.id AS movie_id, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(g.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword g ON mk.keyword_id = g.id
    GROUP BY 
        m.movie_id
),
CompanyDetails AS (
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
),
ActorCount AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mg.genres, 'Unknown') AS genres,
    COALESCE(cd.company_name, 'Independent') AS production_company,
    ac.actor_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    ActorCount ac ON rm.movie_id = ac.movie_id
WHERE 
    rm.rn <= 10 
ORDER BY 
    rm.production_year DESC, rm.title ASC;
