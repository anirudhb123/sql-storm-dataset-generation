WITH RecursiveMovieData AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        ak.person_id,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank,
        COALESCE(NULLIF(SUBSTRING(mt.title FROM '[0-9]{4}'), ''), 'Unknown Year') AS movie_year
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON ci.movie_id = mt.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        mt.production_year IS NOT NULL
),
TotalActors AS (
    SELECT 
        movie_id, 
        COUNT(DISTINCT person_id) AS total_actors
    FROM 
        RecursiveMovieData
    GROUP BY 
        movie_id
),
MovieInfoWithActors AS (
    SELECT 
        rmd.movie_id,
        rmd.title,
        rmd.production_year,
        rmd.actor_name,
        rmd.actor_rank,
        ta.total_actors,
        (SELECT STRING_AGG(name, ', ') 
         FROM aka_name 
         WHERE person_id IN (
             SELECT DISTINCT person_id 
             FROM cast_info 
             WHERE movie_id = rmd.movie_id
         )) AS all_actor_names
    FROM 
        RecursiveMovieData rmd
    JOIN 
        TotalActors ta ON rmd.movie_id = ta.movie_id
),
FinalOutput AS (
    SELECT 
        m.title,
        m.production_year,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Contemporary'
        END AS movie_age_category,
        m.total_actors,
        CASE 
            WHEN m.total_actors IS NULL THEN 'No cast information'
            ELSE 'Has cast information'
        END AS cast_info_status,
        m.all_actor_names,
        RANK() OVER (ORDER BY m.production_year DESC) AS rank_by_production_year
    FROM 
        MovieInfoWithActors m
)
SELECT *
FROM 
    FinalOutput
WHERE 
    (total_actors > 5 AND movie_age_category = 'Classic') 
    OR (total_actors IS NULL AND production_year > 2015)
ORDER BY 
    rank_by_production_year, 
    title ASC;
