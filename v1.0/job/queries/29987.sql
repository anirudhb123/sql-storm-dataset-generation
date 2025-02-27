
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
PopularMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
MovieInfo AS (
    SELECT 
        pm.movie_id,
        STRING_AGG(mi.info, ', ') AS detailed_info
    FROM 
        PopularMovies pm
    LEFT JOIN 
        movie_info mi ON pm.movie_id = mi.movie_id
    GROUP BY 
        pm.movie_id
)
SELECT 
    pm.movie_id,
    pm.movie_title,
    pm.production_year,
    mi.detailed_info,
    COUNT(DISTINCT c.person_id) AS total_cast,
    COUNT(DISTINCT k.keyword) AS total_keywords
FROM 
    PopularMovies pm
LEFT JOIN 
    complete_cast cc ON pm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON pm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieInfo mi ON pm.movie_id = mi.movie_id
GROUP BY 
    pm.movie_id, pm.movie_title, pm.production_year, mi.detailed_info
ORDER BY 
    pm.production_year DESC, total_cast DESC;
