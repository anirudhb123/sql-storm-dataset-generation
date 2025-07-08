WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
), 
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COUNT(cc.id) AS cast_count,
        COALESCE(MAX(CASE WHEN ci.role_id = (SELECT id FROM role_type WHERE role = 'Director') THEN ci.person_id END), 0) AS director_id
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        complete_cast AS cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    a.name AS director_name,
    CASE 
        WHEN md.cast_count < 5 THEN 'Low Cast'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'High Cast'
    END AS cast_size_category
FROM 
    MovieDetails AS md
LEFT JOIN 
    aka_name AS a ON a.person_id = md.director_id
WHERE 
    md.production_year BETWEEN 1990 AND 2020
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
