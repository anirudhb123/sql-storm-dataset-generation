WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY mt.production_year DESC, mt.title) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
),
TopMovies AS (
    SELECT 
        *
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    tm.movie_id, 
    tm.title, 
    tm.production_year, 
    tm.company_count,
    tm.cast_names,
    unnest(tm.keywords) AS keyword
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.title;
