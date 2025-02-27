WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank,
        COUNT(DISTINCT mk.keyword_id) OVER (PARTITION BY at.id) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        *,
        CASE 
            WHEN keyword_count > 5 THEN 'High'
            WHEN keyword_count BETWEEN 3 AND 5 THEN 'Medium'
            ELSE 'Low' 
        END AS keyword_category
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 10
),
ActorsInfo AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id, ak.name
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_category,
    ai.actor_name,
    ai.actor_count
FROM 
    TopMovies tm
LEFT JOIN 
    ActorsInfo ai ON tm.movie_id = ai.movie_id
WHERE 
    tm.keyword_category = 'High'
ORDER BY 
    tm.production_year DESC, 
    ai.actor_count DESC;
