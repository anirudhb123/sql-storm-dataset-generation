WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link m
    JOIN 
        title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
)
, CastDetails AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
)
, MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    cd.actor_name,
    cd.actor_order,
    cd.total_actors,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level = 1 AND 
    (cd.total_actors IS NULL OR cd.total_actors > 5)
ORDER BY 
    mh.production_year DESC, 
    cd.actor_order;
