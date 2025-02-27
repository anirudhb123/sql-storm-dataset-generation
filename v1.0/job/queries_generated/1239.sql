WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        AVG(mi.info::float) AS avg_movie_info_length,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    GROUP BY 
        a.id
),
HighCastMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.avg_movie_info_length
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > (SELECT AVG(cast_count) FROM RankedMovies)
),
NotableMovies AS (
    SELECT 
        h.title,
        h.production_year,
        h.cast_count,
        CASE 
            WHEN h.avg_movie_info_length IS NULL THEN 'No Info'
            ELSE 'Avg Length: ' || h.avg_movie_info_length::text
        END AS avg_info_length
    FROM 
        HighCastMovies h
)
SELECT 
    n.name AS actor_name,
    nm.title AS movie_title,
    nm.production_year,
    nm.avg_info_length,
    COUNT(DISTINCT nm.cast_count) OVER (PARTITION BY nm.production_year) AS total_movies_per_year
FROM 
    name n
JOIN 
    cast_info ci ON n.id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    NotableMovies nm ON nm.production_year = cc.movie_id
WHERE 
    n.gender IS NOT NULL
    AND n.name IS NOT NULL
ORDER BY 
    nm.production_year DESC, actor_name;
