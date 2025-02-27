WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), MovieGenres AS (
    SELECT 
        mt.movie_id, 
        STRING_AGG(kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mt
    JOIN 
        keyword kt ON mt.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
), CompanyData AS (
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_count,
    mg.genres,
    cd.companies,
    cd.company_types
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
LEFT JOIN 
    CompanyData cd ON rm.movie_id = cd.movie_id
ORDER BY 
    rm.actor_count DESC, 
    rm.production_year DESC;
