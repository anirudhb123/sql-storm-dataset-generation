WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        aka_name.name AS actor_name,
        rank() OVER (PARTITION BY title.id ORDER BY title.production_year DESC) AS year_rank
    FROM 
        title
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON aka_name.person_id = cast_info.person_id
    WHERE 
        title.production_year >= 2000
        AND movie_info.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
        AND movie_keyword.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
),
DistinctActors AS (
    SELECT DISTINCT 
        actor_name 
    FROM 
        RankedMovies 
    WHERE 
        year_rank = 1
),
TopMovies AS (
    SELECT 
        movie_title,
        COUNT(actor_name) AS actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_title
    ORDER BY 
        actor_count DESC
    LIMIT 10
)
SELECT 
    T.movie_title, 
    T.actor_count, 
    D.actor_name
FROM 
    TopMovies T
JOIN 
    RankedMovies R ON T.movie_title = R.movie_title
JOIN 
    DistinctActors D ON R.actor_name = D.actor_name
ORDER BY 
    T.actor_count DESC, 
    T.movie_title;
