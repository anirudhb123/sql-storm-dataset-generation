WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(distinct ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        movie_companies mc ON at.movie_id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        company_types,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year BETWEEN 2000 AND 2023
)

SELECT 
    tm.rank,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    tm.company_types
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC;
