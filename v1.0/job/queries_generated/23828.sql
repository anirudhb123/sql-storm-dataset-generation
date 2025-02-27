WITH Recursive ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        ak.name IS NOT NULL
        AND at.production_year IS NOT NULL
),
RatedMovies AS (
    SELECT 
        actor_id,
        movie_title,
        production_year,
        AVG(mv.rating) AS average_rating
    FROM 
        ActorMovies am
    LEFT JOIN 
        movie_info mi ON am.actor_id = mi.movie_id 
    LEFT JOIN 
        (SELECT movie_id, rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) mv ON am.movie_title = mv.movie_id
    GROUP BY 
        actor_id, movie_title, production_year
),
WildcardSearch AS (
    SELECT 
        *
    FROM 
        RatedMovies
    WHERE 
        movie_title LIKE '%The%'
        OR production_year > 2000
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_title) AS movie_count,
        AVG(average_rating) AS avg_rating
    FROM 
        WildcardSearch
    GROUP BY 
        actor_id, actor_name
    HAVING 
        COUNT(movie_title) > 2
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    COALESCE(ta.avg_rating, 0) AS avg_rating,
    CASE 
        WHEN ta.avg_rating IS NOT NULL THEN 'Rated'
        ELSE 'Unrated'
    END AS rating_status,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'comedy%'))) AS comedy_movies_count
FROM 
    TopActors ta
LEFT JOIN 
    complete_cast cc ON ta.actor_id = cc.subject_id
LEFT JOIN 
    (SELECT DISTINCT movie_id FROM movie_info WHERE note IS NOT NULL) mi ON cc.movie_id = mi.movie_id
ORDER BY 
    ta.avg_rating DESC NULLS LAST, 
    ta.movie_count DESC;
