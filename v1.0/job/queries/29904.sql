WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS alternate_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        * 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(NULLIF(tm.alternate_names, '{}'), ARRAY['No Alternate Names']) AS alternate_names,
    COALESCE(NULLIF(tm.keywords, ''), 'No Keywords') AS keywords
FROM 
    TopMovies tm 
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
