WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank_per_year <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        mk.keyword,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    COALESCE(STRING_AGG(DISTINCT md.company_name, ', '), 'No Companies') AS production_companies,
    COUNT(DISTINCT md.company_name) AS unique_production_companies
FROM 
    MovieDetails md
GROUP BY 
    md.title, 
    md.production_year
ORDER BY 
    md.production_year DESC, COUNT(DISTINCT md.company_name) DESC;
