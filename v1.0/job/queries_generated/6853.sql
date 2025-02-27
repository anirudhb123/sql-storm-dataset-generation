WITH RecursiveActorMovies AS (
    SELECT 
        ka.name AS actor_name,
        kt.title AS movie_title,
        kt.production_year,
        COUNT(DISTINCT kc.person_id) AS co_stars_count
    FROM 
        aka_name ka
    JOIN 
        cast_info kc ON ka.person_id = kc.person_id
    JOIN 
        aka_title kt ON kc.movie_id = kt.movie_id
    WHERE 
        kt.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        ka.name, kt.title, kt.production_year
),
PopularMovies AS (
    SELECT 
        movie_title,
        SUM(co_stars_count) AS total_co_stars
    FROM 
        RecursiveActorMovies
    GROUP BY 
        movie_title
    HAVING 
        SUM(co_stars_count) > 10
)

SELECT 
    pm.movie_title,
    pm.total_co_stars,
    ka.name AS main_actor,
    COUNT(DISTINCT kc.person_id) AS all_co_stars
FROM 
    PopularMovies pm
JOIN 
    cast_info kc ON pm.movie_title = (SELECT title FROM aka_title WHERE movie_id = kc.movie_id)
JOIN 
    aka_name ka ON kc.person_id = ka.person_id
GROUP BY 
    pm.movie_title, pm.total_co_stars, ka.name
ORDER BY 
    pm.total_co_stars DESC, pm.movie_title;
