WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episiode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        mv.id AS movie_id,
        mv.title,
        mv.production_year,
        COALESCE(ts.cast_count, 0) AS cast_count,
        COALESCE(ts.has_roles, 0) AS has_roles,
        COALESCE(tk.keywords, 'No Keywords') AS keywords
    FROM 
        aka_title mv
    LEFT JOIN 
        CastStats ts ON mv.id = ts.movie_id
    LEFT JOIN 
        TopKeywords tk ON mv.id = tk.movie_id
)
SELECT 
    md.title AS movie_title,
    md.production_year,
    md.cast_count,
    CASE 
        WHEN md.has_roles = 1 THEN 'Has Roles'
        ELSE 'No Roles'
    END AS role_status,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    MovieHierarchy mh ON md.movie_id = mh.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 50;
