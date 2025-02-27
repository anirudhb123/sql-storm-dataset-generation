WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) as rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
),
MovieInfo AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.actors,
        mt.info AS genre_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mt ON rm.title = mt.info AND mt.info_type_id IN (SELECT id FROM info_type WHERE info = 'genre')
    WHERE 
        rm.rank <= 10
)
SELECT 
    *
FROM 
    MovieInfo
ORDER BY 
    production_year DESC, company_count DESC;

This SQL query aims to benchmark string processing by extracting the top 10 movies produced after the year 2000, ranked by the number of associated companies, while also aggregating their actor names and genre information. It utilizes Common Table Expressions (CTEs) for structured querying, including joins across multiple tables, and demonstrates complex string manipulation in the aggregating actor names.
