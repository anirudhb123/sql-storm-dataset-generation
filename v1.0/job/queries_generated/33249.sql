WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COALESCE(cr.total_cast, 0) AS total_cast,
        cr.cast_names,
        ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastRoles cr ON mh.movie_id = cr.movie_id
)
SELECT 
    md.title,
    md.production_year,
    c.kind AS kind_type,
    md.total_cast,
    md.cast_names
FROM 
    MovieDetails md
LEFT JOIN 
    kind_type c ON md.kind_id = c.id
WHERE 
    md.total_cast > 0
    AND md.production_year >= 2000
    AND (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = md.movie_id) > 5
ORDER BY 
    md.production_year DESC,
    md.movie_rank
LIMIT 10;
