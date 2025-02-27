
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS production_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
AggregatedGenres AS (
    SELECT 
        kt.keyword AS genre,
        mt.production_year,
        COUNT(mk.id) AS genre_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        kt.keyword, mt.production_year
),
FinalStats AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast,
        COALESCE(ag.genre_count, 0) AS genre_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        AggregatedGenres ag ON rm.production_year = ag.production_year
    WHERE 
        rm.production_rank <= 5
)
SELECT 
    fs.title,
    fs.production_year,
    fs.total_cast,
    fs.genre_count,
    CASE 
        WHEN fs.genre_count < 5 THEN 'Low Genre Count' 
        WHEN fs.genre_count BETWEEN 5 AND 10 THEN 'Medium Genre Count' 
        ELSE 'High Genre Count' 
    END AS genre_assessment
FROM 
    FinalStats fs
ORDER BY 
    fs.production_year DESC, fs.total_cast DESC;
