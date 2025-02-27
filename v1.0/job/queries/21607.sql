WITH RecursiveActor AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role,
        tm.title AS movie_title,
        tm.production_year,
        ROW_NUMBER() OVER(PARTITION BY ak.person_id ORDER BY tm.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title tm ON ci.movie_id = tm.movie_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ak.name IS NOT NULL
),
MoviesByYear AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_title) AS movie_count,
        MAX(production_year) AS latest_year,
        MIN(production_year) AS earliest_year
    FROM 
        RecursiveActor
    GROUP BY 
        production_year
    HAVING 
        COUNT(DISTINCT movie_title) > 5
),
TopActors AS (
    SELECT 
        actor_name,
        SUM(CASE WHEN recent_movie_rank = 1 THEN 1 ELSE 0 END) AS top_movie_count
    FROM 
        RecursiveActor
    GROUP BY 
        actor_name
    HAVING 
        SUM(CASE WHEN recent_movie_rank = 1 THEN 1 ELSE 0 END) > 3
)
SELECT
    a.actor_name,
    COALESCE(m.movie_count, 0) AS film_count,
    a.top_movie_count,
    aa.latest_year,
    aa.earliest_year,
    (SELECT STRING_AGG(title, ', ') 
     FROM aka_title 
     WHERE production_year = aa.latest_year) AS latest_movie_titles,
    CASE 
        WHEN m.movie_count IS NULL THEN 'No Movies Found'
        ELSE 'Movies Found'
    END AS movie_status
FROM 
    TopActors a
LEFT JOIN 
    MoviesByYear m ON 1 = 1 
LEFT JOIN 
    (SELECT 
         MAX(production_year) AS latest_year, 
         MIN(production_year) AS earliest_year 
     FROM 
         MoviesByYear) aa ON 1 = 1
WHERE 
    a.top_movie_count IS NOT NULL 
ORDER BY 
    a.top_movie_count DESC, 
    a.actor_name ASC
LIMIT 50;