WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorMovieCount AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        ac.movie_count,
        ROW_NUMBER() OVER (ORDER BY ac.movie_count DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        ActorMovieCount ac ON a.person_id = ac.person_id
    WHERE 
        ac.movie_count >= 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ta.name AS top_actor,
    ta.movie_count,
    COALESCE(mkw.keywords, 'None') AS keywords,
    mh.level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    TopActors ta ON cc.subject_id = ta.person_id
LEFT JOIN 
    MoviesWithKeywords mkw ON mh.movie_id = mkw.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.production_year DESC, mh.title;
