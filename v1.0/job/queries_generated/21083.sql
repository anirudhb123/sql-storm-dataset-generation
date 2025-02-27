WITH MovieRankings AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL 
          AND mt.title IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        rank_within_year
    FROM 
        MovieRankings
    WHERE 
        rank_within_year <= 5
),
ActorInfo AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        ak.person_id,
        COALESCE(pi.info, 'No Info') AS additional_info
    FROM 
        aka_name ak
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        ak.name IS NOT NULL 
          AND ak.name <> ''
),
AggregateCounts AS (
    SELECT 
        tm.movie_id,
        tm.title,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ai.name, ', ') AS actor_names
    FROM 
        TopMovies tm
    JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        ActorInfo ai ON ci.person_id = ai.person_id
    GROUP BY 
        tm.movie_id, tm.title
)
SELECT 
    ac.movie_id,
    ac.title,
    ac.total_actors,
    ac.actor_names,
    CASE 
        WHEN ac.total_actors IS NULL THEN 'No Cast'
        WHEN ac.total_actors > 10 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    md.imdb_index AS movie_imdb_index,
    ((SELECT AVG(t.production_year)::FLOAT FROM aka_title t WHERE t.production_year IS NOT NULL) 
        - tm.production_year) AS years_from_average
FROM 
    AggregateCounts ac
LEFT JOIN 
    aka_title md ON ac.movie_id = md.id
LEFT JOIN 
    (SELECT 
        DISTINCT production_year 
     FROM 
        aka_title 
     WHERE 
        production_year IS NOT NULL) pr_year ON 1=1
WHERE 
    (ac.total_actors IS NOT NULL OR ac.actor_names IS NOT NULL)
ORDER BY 
    ac.total_actors DESC NULLS LAST, 
    ac.title;
