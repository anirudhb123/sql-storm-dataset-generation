WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link AS m
    JOIN 
        aka_title AS mt ON mt.id = m.linked_movie_id
    JOIN 
        MovieHierarchy AS mh ON mh.movie_id = m.movie_id
),
GenreStatistics AS (
    SELECT 
        mw.movie_id,
        COUNT(DISTINCT k.keyword) AS genre_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword AS mw
    JOIN 
        keyword AS k ON mw.keyword_id = k.id
    GROUP BY 
        mw.movie_id
),
TopActors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.person_id) AS appearances
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
    ORDER BY 
        appearances DESC
),
CompleteMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        gs.genre_count,
        gs.genres,
        COALESCE(ta.actor_name, 'Unknown Actor') AS top_actor,
        COALESCE(ta.appearances, 0) AS top_actor_appearances
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        GenreStatistics AS gs ON mh.movie_id = gs.movie_id
    LEFT JOIN 
        (SELECT 
             movie_id, actor_name, appearances
         FROM 
             TopActors
         ORDER BY 
             appearances DESC
         LIMIT 1) AS ta ON mh.movie_id = ta.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    genre_count,
    genres,
    top_actor,
    top_actor_appearances
FROM 
    CompleteMovieInfo
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, genre_count DESC;

