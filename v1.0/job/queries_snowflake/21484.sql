
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COALESCE(mk.keyword_count, 0) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS keyword_count 
        FROM 
            movie_keyword 
        GROUP BY 
            movie_id
    ) mk ON t.id = mk.movie_id
),  
MovieWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        CASE WHEN ci.person_id IS NULL THEN 'No Cast' ELSE 'Has Cast' END AS cast_status,
        COUNT(ci.person_id) AS cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, cast_status
), 
TopCastMovies AS (
    SELECT 
        mwc.movie_id,
        mwc.title,
        mwc.production_year,
        mwc.cast_status,
        mwc.cast_count,
        SUM(CASE WHEN mwc.cast_count > 0 THEN 1 ELSE 0 END) OVER (PARTITION BY mwc.production_year) AS total_cast_movies
    FROM 
        MovieWithCast mwc
)
SELECT 
    title, 
    production_year,
    cast_status,
    cast_count,
    total_cast_movies,
    (CASE 
         WHEN total_cast_movies = 0 THEN 'No Movies Available'
         ELSE CAST(CAST(cast_count AS FLOAT) / NULLIF(total_cast_movies, 0) * 100 AS NUMBER(5, 2)) || '%' 
     END) AS cast_percentage,
    (SELECT LISTAGG(DISTINCT cn.name, ', ') 
     FROM company_name cn 
     JOIN movie_companies mc ON mc.movie_id = t.movie_id 
     WHERE mc.company_id = cn.id
     GROUP BY mc.movie_id) AS companies_involved
FROM 
    TopCastMovies t
WHERE 
    (production_year BETWEEN 2000 AND 2023) AND 
    (cast_count <= ALL (SELECT cast_count FROM TopCastMovies)) OR
    (production_year IS NULL) 
ORDER BY 
    production_year DESC, 
    cast_count DESC 
LIMIT 10;
