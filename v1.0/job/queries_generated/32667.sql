WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        CAST(NULL AS INTEGER) AS parent_movie_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        mh.movie_id AS parent_movie_id,
        mh.depth + 1
    FROM 
        aka_title e
    INNER JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
ActorContribution AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movies_count,
        SUM(CASE WHEN m.production_year BETWEEN 1990 AND 2020 THEN 1 ELSE 0 END) AS movies_in_period
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        ac.person_id,
        ac.movies_count,
        ac.movies_in_period,
        RANK() OVER (ORDER BY ac.movies_in_period DESC) AS rank
    FROM 
        ActorContribution ac
    WHERE 
        ac.movies_count > 5
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.parent_movie_id,
        mh.depth,
        t.production_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        aka_title t ON mh.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
)
SELECT 
    a.id AS actor_id,
    a.name AS actor_name,
    fm.title AS movie_title,
    fm.production_year,
    fh.depth AS hierarchy_depth
FROM 
    TopActors ta
INNER JOIN 
    aka_name a ON ta.person_id = a.person_id
LEFT JOIN 
    FilteredMovies fm ON fm.movie_id IN (
        SELECT 
            c.movie_id 
        FROM 
            cast_info c 
        WHERE 
            c.person_id = a.person_id
    )
LEFT JOIN 
    MovieHierarchy fh ON fm.movie_id = fh.movie_id
WHERE 
    fh.depth IS NOT NULL
ORDER BY 
    a.name, fm.production_year DESC;
