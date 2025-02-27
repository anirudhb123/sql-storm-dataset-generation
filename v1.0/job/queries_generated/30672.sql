WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5  -- limit the hierarchy depth
),
AverageRoleCount AS (
    SELECT 
        ci.role_id, 
        COUNT(DISTINCT ci.person_id) AS total_actors,
        AVG(m.total_movies) AS avg_movies_per_role
    FROM 
        cast_info ci
    JOIN (
        SELECT 
            movie_id, 
            COUNT(DISTINCT person_id) AS total_movies
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) m ON ci.movie_id = m.movie_id
    GROUP BY 
        ci.role_id
),
MoviesWithKeywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id, mt.title
)

SELECT 
    mh.movie_id, 
    mh.title, 
    mh.production_year,
    COALESCE(kw.keywords, 'No Keywords') AS keywords,
    COALESCE(rc.total_actors, 0) AS actor_count,
    rc.avg_movies_per_role
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MoviesWithKeywords kw ON mh.movie_id = kw.movie_id
LEFT JOIN 
    AverageRoleCount rc ON mh.movie_id = rc.role_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, mh.title ASC
LIMIT 50;
