WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CASE 
            WHEN mt.kind_id = 1 THEN 'Feature Film'
            WHEN mt.kind_id = 2 THEN 'Short Film'
            ELSE 'Other'
        END AS movie_type,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS row_num
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorMovieCTE AS (
    SELECT 
        ci.person_id,
        mt.title,
        mt.production_year,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        RecursiveMovieCTE mt ON ci.movie_id = mt.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.person_id, mt.title, mt.production_year
)
SELECT 
    am.person_id,
    am.movie_count,
    am.actor_names,
    rm.movie_id,
    rm.title AS recent_movie,
    rm.production_year AS recent_year
FROM 
    ActorMovieCTE am
LEFT JOIN 
    (SELECT 
        person_id, 
        movie_id, 
        title, 
        production_year
     FROM 
        ActorMovieCTE
     WHERE 
         row_num = 1
    ) rm ON am.person_id = rm.person_id
WHERE 
    am.movie_count > 1
ORDER BY 
    am.movie_count DESC, 
    rm.production_year DESC
FETCH FIRST 10 ROWS ONLY;
