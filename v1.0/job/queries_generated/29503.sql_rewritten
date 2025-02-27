WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COALESCE(cast_count.cast_count, 0) AS cast_count,
        km.keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COALESCE(cast_count.cast_count, 0) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT ci.person_id) AS cast_count
        FROM 
            cast_info ci
        GROUP BY 
            ci.movie_id
    ) cast_count ON a.id = cast_count.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) km ON a.id = km.movie_id
)
SELECT 
    r.movie_title,
    r.production_year,
    r.cast_count,
    r.keywords
FROM 
    RankedMovies r
WHERE 
    r.rank <= 10
ORDER BY 
    r.production_year DESC, r.cast_count DESC;