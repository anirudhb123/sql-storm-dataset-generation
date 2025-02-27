WITH RecursiveMovieCTE AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS movie_rank
    FROM title
    WHERE title.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        aka_name.name AS actor_name,
        aka_name.person_id,
        COUNT(cast_info.movie_id) AS total_movies,
        AVG(COALESCE(movie_info.info, '')::numeric) AS average_movie_rating,
        SUM(CASE WHEN movie_info.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM aka_name
    JOIN cast_info ON aka_name.person_id = cast_info.person_id
    LEFT JOIN movie_info ON cast_info.movie_id = movie_info.movie_id AND movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY aka_name.name, aka_name.person_id
),
TopActors AS (
    SELECT 
        actor_name, 
        total_movies,
        average_movie_rating,
        DENSE_RANK() OVER (ORDER BY total_movies DESC, average_movie_rating DESC) AS rnk
    FROM ActorDetails
    WHERE total_movies > 5
),
MoviesWithActors AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        a.actor_name,
        a.average_movie_rating
    FROM RecursiveMovieCTE m
    JOIN cast_info c ON m.movie_id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE m.movie_rank <= 5 AND m.production_year BETWEEN 2000 AND 2023
),
FinalComparison AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(a.actor_name, 'No Actor') AS actor_name,
        COALESCE(a.average_movie_rating, 0) AS average_rating,
        CASE WHEN a.average_movie_rating IS NULL THEN 'No Rating' ELSE 'Rated' END AS rating_status
    FROM RecursiveMovieCTE AS m
    LEFT JOIN TopActors AS a ON m.title = a.actor_name
)
SELECT 
    f.title,
    f.production_year,
    f.actor_name,
    f.average_rating,
    f.rating_status,
    COUNT(m.title) OVER (PARTITION BY f.actor_name) AS movies_acted,
    ROW_NUMBER() OVER (PARTITION BY f.actor_name ORDER BY f.average_rating DESC) AS actor_movie_rank
FROM FinalComparison f
ORDER BY f.production_year DESC, f.average_rating DESC
LIMIT 100;
