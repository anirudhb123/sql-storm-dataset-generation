WITH ActorStats AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(t.production_year) AS average_year,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
),
GenreStats AS (
    SELECT 
        kt.kind AS genre_name,
        COUNT(DISTINCT t.id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        kt.kind
),
CompanyStats AS (
    SELECT 
        cn.name AS company_name,
        COUNT(mc.movie_id) AS movies_produced,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON cn.id = mc.company_id
    JOIN 
        aka_title t ON mc.movie_id = t.id
    GROUP BY 
        cn.name
)
SELECT 
    a.actor_name,
    a.movie_count AS actor_movie_count,
    a.average_year AS actor_average_year,
    a.movies AS actor_movies,
    g.genre_name,
    g.movie_count AS genre_movie_count,
    g.movies AS genre_movies,
    c.company_name,
    c.movies_produced,
    c.titles
FROM 
    ActorStats a
FULL OUTER JOIN 
    GenreStats g ON a.movies ILIKE '%' || g.movies || '%'
FULL OUTER JOIN 
    CompanyStats c ON a.movies ILIKE '%' || c.titles || '%'
ORDER BY 
    a.movie_count DESC, g.movie_count DESC, c.movies_produced DESC
LIMIT 50;
