
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2022
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),

TopMovieKeywords AS (
    SELECT 
        movie_id,
        ARRAY_AGG(DISTINCT keyword) AS keywords,
        AVG(cast_count) AS avg_cast_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_id
    HAVING 
        COUNT(DISTINCT keyword) > 3
)

SELECT 
    t.title,
    t.production_year,
    mk.keywords,
    mk.avg_cast_count
FROM 
    aka_title t
JOIN 
    TopMovieKeywords mk ON t.id = mk.movie_id
ORDER BY 
    mk.avg_cast_count DESC,
    t.production_year ASC;
