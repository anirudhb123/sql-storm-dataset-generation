WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    INNER JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id 
    WHERE 
        mh.depth < 3 
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

RankedMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.actor_count,
        fm.actor_names,
        ROW_NUMBER() OVER (
            PARTITION BY fm.production_year 
            ORDER BY fm.actor_count DESC, fm.title ASC
        ) AS rn
    FROM 
        FilteredMovies fm
    WHERE 
        fm.actor_count > 5 
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.actor_count,
    r.actor_names,
    CASE 
        WHEN r.actor_count IS NULL THEN 'No Actors'
        WHEN r.actor_count >= 15 THEN 'Popular Movie'
        WHEN r.actor_count < 10 THEN 'Lesser Known'
        ELSE 'Moderate Success'
    END AS popularity_category,
    (SELECT AVG(actor_count) FROM FilteredMovies) AS average_actor_count 
FROM 
    RankedMovies r
WHERE 
    r.rn <= 10 
ORDER BY 
    r.production_year DESC, r.actor_count DESC;