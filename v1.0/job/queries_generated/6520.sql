WITH RecursiveActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
PopularKeywords AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(mk.movie_id) > 50
),
RecentMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.company_id
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    WHERE 
        t.production_year >= 2020
)
SELECT 
    actor_movies.actor_name,
    actor_movies.movie_title,
    actor_movies.production_year,
    ARRAY_AGG(DISTINCT pk.keyword) AS popular_keywords
FROM 
    RecursiveActorMovies actor_movies
LEFT JOIN 
    movie_keyword mk ON actor_movies.movie_id = mk.movie_id
LEFT JOIN 
    PopularKeywords pk ON mk.keyword_id = pk.id
JOIN 
    RecentMovies rm ON actor_movies.movie_id = rm.movie_id
WHERE 
    actor_movies.movie_rank <= 3
GROUP BY 
    actor_movies.actor_id, actor_movies.actor_name, actor_movies.movie_title, actor_movies.production_year
ORDER BY 
    actor_movies.actor_name, actor_movies.production_year DESC;
