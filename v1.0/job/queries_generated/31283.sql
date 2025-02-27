WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        1 AS level
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
    
    UNION ALL
    
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        cm.linked_movie_id AS movie_id,
        ah.level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        movie_link ml ON ah.movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        aka_name a ON a.id = t.imdb_id
    WHERE 
        ah.level < 5  -- Limit the level to avoid deep recursion
),
FilteredMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
ActorMovieInfo AS (
    SELECT 
        ah.actor_id,
        ah.actor_name,
        fm.movie_id,
        fm.title,
        fm.production_year
    FROM 
        ActorHierarchy ah
    JOIN 
        FilteredMovies fm ON ah.movie_id = fm.movie_id
)
SELECT 
    ami.actor_id,
    ami.actor_name,
    ami.movie_id,
    ami.title,
    ami.production_year,
    COALESCE(ki.keyword, 'No keyword') AS keyword,
    COUNT(*) OVER (PARTITION BY ami.actor_id) AS total_movies,
    RANK() OVER (PARTITION BY ami.actor_id ORDER BY ami.production_year DESC) AS rank_by_year
FROM 
    ActorMovieInfo ami
LEFT JOIN 
    movie_keyword mk ON ami.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    ami.production_year >= 2000
ORDER BY 
    ami.actor_id, 
    ami.production_year DESC;
