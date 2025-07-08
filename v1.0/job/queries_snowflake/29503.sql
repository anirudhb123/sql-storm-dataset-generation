
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COALESCE(cast_count.cast_count, 0) AS cast_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
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
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.title,
        a.production_year,
        cast_count.cast_count
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
