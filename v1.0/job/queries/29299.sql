WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COUNT(DISTINCT mi.info_type_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year, ak.name
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY info_count DESC) AS overall_rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    tm.info_count,
    tm.overall_rank
FROM 
    TopMovies tm
WHERE 
    tm.overall_rank <= 10
ORDER BY 
    tm.production_year DESC, tm.info_count DESC;