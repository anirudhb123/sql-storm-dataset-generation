WITH RECURSIVE ActorMovies AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        t.production_year > 2000
),
AggregateMovieData AS (
    SELECT 
        person_id,
        actor_name,
        COUNT(movie_title) AS total_movies,
        MAX(production_year) AS last_movie_year
    FROM 
        ActorMovies
    GROUP BY 
        person_id, actor_name
),
TopActors AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_movies DESC) AS actor_rank
    FROM 
        AggregateMovieData
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ta.actor_name,
    ta.total_movies,
    ta.last_movie_year,
    cs.total_companies,
    CASE 
        WHEN ta.last_movie_year IS NULL THEN 'No Movies'
        WHEN ta.total_movies > 10 THEN 'A-List'
        WHEN ta.total_movies BETWEEN 5 AND 10 THEN 'B-List'
        ELSE 'C-List'
    END AS actor_category
FROM 
    TopActors ta
LEFT JOIN 
    ActorMovies am ON ta.person_id = am.person_id
LEFT JOIN 
    CompanyStats cs ON am.movie_id = cs.movie_id
WHERE 
    ta.actor_rank <= 50
ORDER BY 
    ta.total_movies DESC, ta.actor_name;
