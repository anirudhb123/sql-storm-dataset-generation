WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS total_cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS row_num
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
ActorStats AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT m.movie_id) AS movies_count,
        AVG(m.production_year) AS average_produced_year,
        STRING_AGG(DISTINCT m.title, ', ') AS movies_acted_in
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        RecursiveMovieCTE m ON cc.movie_id = m.movie_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
),
FilteredActorStats AS (
    SELECT 
        as.actor_name,
        as.movies_count,
        as.average_produced_year
    FROM (
        SELECT 
            ak.name AS actor_name,
            ak.movies_count, 
            ak.average_produced_year 
        FROM 
            ActorStats ak
        WHERE 
            ak.movies_count > 5
            AND ak.average_produced_year < 2000
    ) as
    WHERE 
        actor_name NOT IN (SELECT DISTINCT name FROM char_name WHERE name IS NULL)
)
SELECT 
    fas.actor_name,
    fas.movies_count,
    fas.average_produced_year,
    COALESCE(REPLACE(STRING_AGG(m.title, ', '), 'NULL', ''), 'No Titles') AS movies_list,
    ROUND(AVG(NULLIF(fas.movies_count, 0)), 2) OVER () AS avg_movies_count,
    COUNT(m.movie_id) FILTER (WHERE m.production_year BETWEEN 1990 AND 2000) AS count_90s_movies
FROM 
    FilteredActorStats fas
LEFT JOIN 
    RecursiveMovieCTE m ON fas.actor_name = m.title
GROUP BY 
    fas.actor_name,
    fas.movies_count,
    fas.average_produced_year
ORDER BY 
    fas.movies_count DESC, 
    fas.average_produced_year ASC
LIMIT 10;
