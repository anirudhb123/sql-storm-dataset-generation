WITH RECURSIVE ActorMovies AS (
    SELECT 
        ca.id AS cast_id,
        ca.person_id,
        ca.movie_id,
        at.title AS movie_title,
        at.production_year,
        1 AS depth
    FROM cast_info ca
    JOIN aka_name an ON ca.person_id = an.person_id
    JOIN aka_title at ON ca.movie_id = at.movie_id
    WHERE an.name ILIKE '%Smith%' -- Filtering for actors with surname 'Smith'
    
    UNION ALL
    
    SELECT 
        ca.id AS cast_id,
        ca.person_id,
        ca.movie_id,
        at.title AS movie_title,
        at.production_year,
        depth + 1
    FROM cast_info ca
    JOIN aka_title at ON ca.movie_id = at.movie_id
    JOIN actor_movies am ON ca.person_id = am.person_id
    WHERE ca.movie_id <> am.movie_id -- Preventing self-referencing within the recursion
)

SELECT 
    am.person_id,
    an.name,
    COUNT(DISTINCT am.movie_id) AS total_movies,
    STRING_AGG(DISTINCT am.movie_title, ', ') AS movie_titles,
    MIN(am.production_year) AS earliest_movie,
    MAX(am.production_year) AS latest_movie,
    RANK() OVER (PARTITION BY am.person_id ORDER BY COUNT(DISTINCT am.movie_id) DESC) AS rank_by_movies
FROM ActorMovies am
JOIN aka_name an ON am.person_id = an.person_id
GROUP BY am.person_id, an.name
HAVING COUNT(DISTINCT am.movie_id) > 5 -- Actors with more than 5 movies
ORDER BY rank_by_movies, an.name;

-- Performing an outer join with role type to get the roles played 
SELECT 
    am.person_id,
    an.name,
    rt.role AS character_role,
    COUNT(DISTINCT am.movie_id) AS total_movies,
    SUBSTRING(STRING_AGG(DISTINCT am.movie_title, ', ') FROM 1 FOR 100) AS movie_titles_truncated,
    RANK() OVER (ORDER BY COUNT(DISTINCT am.movie_id) DESC) AS rank_by_movies
FROM ActorMovies am
JOIN aka_name an ON am.person_id = an.person_id
LEFT JOIN cast_info ci ON am.movie_id = ci.movie_id AND am.person_id = ci.person_id
LEFT JOIN role_type rt ON ci.role_id = rt.id
GROUP BY am.person_id, an.name, rt.role
HAVING COUNT(DISTINCT am.movie_id) > 10 -- More than 10 movies
ORDER BY rank_by_movies DESC, an.name;
