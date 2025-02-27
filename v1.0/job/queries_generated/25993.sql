WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(c.id) > 5
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        mci.company_id,
        c.name AS company_name,
        k.keyword AS movie_keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mci ON rm.movie_id = mci.movie_id 
    LEFT JOIN 
        company_name c ON mci.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.cast_count,
        STRING_AGG(DISTINCT md.company_name, ', ') AS companies,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_id, md.movie_title, md.production_year, md.cast_count
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    cast_count,
    companies,
    keywords
FROM 
    FinalResults
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 100;
