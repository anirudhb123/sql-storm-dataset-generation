WITH ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        a.imdb_index AS actor_imdb_index,
        r.role AS role_type,
        COUNT(ci.movie_id) AS total_movies
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY a.id, a.name, a.imdb_index, r.role
),

MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT g.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword g ON mk.keyword_id = g.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
),

ActorMovieCount AS (
    SELECT 
        actor_id,
        actor_name,
        role_type,
        SUM(total_movies) AS movies_per_role
    FROM ActorInfo
    GROUP BY actor_id, actor_name, role_type
)

SELECT 
    amc.actor_name AS Actor,
    amc.role_type AS Role,
    amc.movies_per_role AS Total_Movies_By_Role,
    md.movie_title AS Movie_Title,
    md.production_year AS Production_Year,
    md.keywords AS Keywords,
    md.cast_count AS Cast_Count
FROM ActorMovieCount amc
JOIN MovieDetails md ON amc.movies_per_role = md.cast_count 
WHERE amc.movies_per_role > 5
ORDER BY md.production_year DESC, amc.actor_name ASC;

This query is designed to analyze the string processing capabilities of a SQL engine by aggregating and filtering actor and movie information. It includes multiple common table expressions (CTEs) to break down the process, ensuring an intricate join logic and dynamic columns for analysis, making it engaging for benchmarking.
