WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        title.kind_id,
        COUNT(cast_info.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(cast_info.person_id) DESC) AS rank_by_cast
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year, title.kind_id
),
HighCastMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast <= 5
),
ActorsInfo AS (
    SELECT 
        aka_name.name AS actor_name,
        aka_name.person_id,
        COUNT(cast_info.movie_id) AS movies_count
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    WHERE 
        aka_name.name IS NOT NULL
    GROUP BY 
        aka_name.name, aka_name.person_id
),
TopActors AS (
    SELECT 
        actor_name, 
        movies_count,
        ROW_NUMBER() OVER (ORDER BY movies_count DESC) AS actor_rank
    FROM 
        ActorsInfo
    WHERE 
        movies_count > 1  -- Exclude actors with only one movie
)
SELECT 
    HCM.movie_id,
    HCM.title,
    HCM.production_year,
    TA.actor_name AS top_actor,
    TA.movies_count AS actor_movies_count,
    COALESCE(info.info, 'No additional info') AS movie_info,
    CASE 
        WHEN HCM.production_year >= 2000 THEN 'Modern'
        ELSE 'Classic'
    END AS movie_age_category
FROM 
    HighCastMovies HCM
LEFT JOIN 
    movie_info info ON HCM.movie_id = info.movie_id 
    AND info.info_type_id IN (SELECT id FROM info_type WHERE info = 'tagline')  -- abnormal inner join
LEFT JOIN 
    TopActors TA ON TA.actor_rank = 1  -- Get the actor with the highest number of movies
WHERE 
    HCM.production_year IS NOT NULL
ORDER BY 
    HCM.production_year DESC, 
    TA.movies_count DESC 
LIMIT 10;
