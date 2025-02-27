WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorMovies AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS number_of_movies,
        STRING_AGG(DISTINCT at.title, ', ') AS titles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    GROUP BY 
        ak.name
),
TopActors AS (
    SELECT 
        actor_name,
        number_of_movies,
        titles,
        RANK() OVER (ORDER BY number_of_movies DESC) AS rank
    FROM 
        ActorMovies
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        COALESCE(mt.kind, 'Unknown') AS movie_kind
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        kind_type mt ON mh.movie_id = mt.id
)
SELECT 
    ta.actor_name,
    ta.number_of_movies,
    ta.titles,
    fm.title AS related_movie,
    fm.movie_kind,
    fm.level
FROM 
    TopActors ta
LEFT JOIN 
    FilteredMovies fm ON fm.movie_kind = 'Comedy' AND fm.level <= 3
WHERE 
    ta.rank <= 10
ORDER BY 
    ta.number_of_movies DESC, 
    fm.level ASC;
