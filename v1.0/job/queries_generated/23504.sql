WITH RecursiveMovieYears AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title ASC) AS year_rank
    FROM 
        title
),
ActorPerformance AS (
    SELECT 
        aka_name.person_id,
        aka_name.name,
        COUNT(DISTINCT cast_info.movie_id) AS total_movies,
        SUM(CASE 
            WHEN movie_info.info LIKE '%Award%' THEN 1 
            ELSE 0 END) AS awards_count,
        AVG(RANK() OVER (PARTITION BY aka_name.person_id ORDER BY movie_companies.company_type_id)) AS avg_company_rank
    FROM 
        aka_name
    LEFT JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    LEFT JOIN 
        complete_cast ON cast_info.movie_id = complete_cast.movie_id
    LEFT JOIN 
        movie_companies ON complete_cast.movie_id = movie_companies.movie_id
    LEFT JOIN 
        movie_info ON movie_companies.movie_id = movie_info.movie_id
    WHERE 
        movie_info.info_type_id IN (SELECT id FROM info_type WHERE info = 'Awards')
    GROUP BY 
        aka_name.person_id, aka_name.name
),
NotableActors AS (
    SELECT 
        person_id,
        name,
        total_movies,
        awards_count,
        avg_company_rank
    FROM 
        ActorPerformance
    WHERE 
        total_movies > 5 AND 
        (awards_count >= 2 OR avg_company_rank < 3)
),
NotableMovies AS (
    SELECT 
        mv.movie_id,
        mv.title,
        mv.production_year,
        COALESCE(actors.name, 'Unknown Actor') AS main_actor,
        mv.year_rank,
        CASE 
            WHEN mv.production_year IS NULL THEN 'Unknown Year' 
            WHEN mv.production_year > 2000 THEN 'Modern Film' 
            ELSE 'Classic Film' 
        END AS film_category
    FROM 
        RecursiveMovieYears AS mv
    LEFT JOIN 
        cast_info AS ci ON mv.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name AS actors ON ci.person_id = actors.person_id
),
FinalSelection AS (
    SELECT 
        movies.title,
        COUNT(DISTINCT actors.person_id) AS main_actor_count,
        ARRAY_AGG(DISTINCT movies.main_actor) AS actor_list,
        movies.film_category
    FROM 
        NotableMovies AS movies
    JOIN 
        NotableActors AS actors ON movies.main_actor = actors.name
    GROUP BY 
        movies.title, movies.film_category
)
SELECT 
    f.title,
    f.main_actor_count,
    STRING_AGG(DISTINCT f.actor_list, ', ') AS unique_actors,
    f.film_category
FROM 
    FinalSelection AS f
WHERE 
    f.main_actor_count > 0
GROUP BY 
    f.title, f.main_actor_count, f.film_category
ORDER BY 
    f.film_category ASC, f.title DESC;
