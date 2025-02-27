WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000 
        AND rm.cast_count > 5
    ORDER BY 
        rm.cast_count DESC
    LIMIT 10
)

SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    fm.cast_count,
    fm.keyword_count,
    ARRAY_AGG(DISTINCT ak.name) AS actor_names,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    FilteredMovies fm
JOIN 
    cast_info ci ON fm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    fm.movie_id, fm.movie_title, fm.production_year, fm.cast_count, fm.keyword_count
ORDER BY 
    fm.cast_count DESC;
