WITH RECURSIVE ActorMovies AS (
    SELECT 
        c.person_id,
        ct.kind AS role_type,
        COUNT(DISTINCT mi.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    JOIN 
        aka_title at ON c.movie_id = at.movie_id
    JOIN 
        movie_info mi ON c.movie_id = mi.movie_id
    WHERE 
        ct.kind LIKE 'Actor%'
    GROUP BY 
        c.person_id, ct.kind
), 

ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COALESCE(SUM(am.movie_count), 0) AS total_movies
    FROM 
        aka_name a
    LEFT JOIN 
        ActorMovies am ON a.person_id = am.person_id
    GROUP BY 
        a.id, a.name
), 

FilteredActors AS (
    SELECT
        ad.actor_id,
        ad.actor_name,
        ad.total_movies,
        RANK() OVER (ORDER BY ad.total_movies DESC) AS rank
    FROM 
        ActorDetails ad
    WHERE 
        ad.total_movies > 5
)

SELECT 
    fa.actor_id,
    fa.actor_name,
    fa.total_movies,
    fa.rank,
    (SELECT STRING_AGG(DISTINCT at.title, ', ') 
     FROM aka_title at 
     JOIN cast_info c ON at.movie_id = c.movie_id 
     WHERE c.person_id = fa.actor_id) AS movie_titles
FROM 
    FilteredActors fa
ORDER BY 
    fa.rank;
