WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL::text AS parent_title,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
CastStats AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS named_roles,
        COUNT(CASE WHEN c.note IS NOT NULL THEN 1 END) AS note_roles
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(cs.named_roles, 0) AS named_roles,
        COALESCE(cs.note_roles, 0) AS note_roles,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC, mh.title) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastStats cs ON mh.movie_id = cs.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.named_roles,
    md.note_roles,
    CASE 
        WHEN md.total_cast > 10 THEN 'Large Cast'
        WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    MovieDetails md
WHERE 
    md.rn <= 10
ORDER BY 
    md.production_year DESC, md.title;
