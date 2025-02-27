WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ka.person_id) AS cast_count,
        STRING_AGG(DISTINCT ka.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        rm.keywords,
        ROW_NUMBER() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5
)
SELECT 
    tm.rank,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    'Contains keywords: ' || tm.keywords AS keyword_summary
FROM 
    TopRatedMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
