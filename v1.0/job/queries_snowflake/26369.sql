WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year > 2000 
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.movie_keyword,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank = 1 
),
KeywordStats AS (
    SELECT 
        movie_keyword,
        COUNT(movie_title) AS movie_count,
        AVG(cast_count) AS average_cast_size
    FROM 
        FilteredMovies
    GROUP BY 
        movie_keyword
)
SELECT 
    ks.movie_keyword,
    ks.movie_count,
    ks.average_cast_size
FROM 
    KeywordStats ks
ORDER BY 
    ks.movie_count DESC, ks.average_cast_size DESC
LIMIT 10;