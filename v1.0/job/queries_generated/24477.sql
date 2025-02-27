WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level,
        ARRAY[t.title] AS title_path
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1,
        mh.title_path || t.title
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title t ON t.episode_of_id = mh.movie_id
)

, CastDetails AS (
    SELECT 
        ci.movie_id,
        r.role AS role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
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
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.kind_id,
    COALESCE(cd.role, 'Unknown Role') AS role,
    COALESCE(cd.actor_name, 'No Actor') AS actor_name,
    mh.level,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT cd.actor_name) OVER(PARTITION BY mh.movie_id) AS total_actors,
    CASE 
        WHEN mh.production_year BETWEEN 2000 AND 2023 THEN 'Modern Era'
        WHEN mh.production_year < 2000 AND mh.production_year IS NOT NULL THEN 'Classic Era'
        ELSE 'Unknown Era'
    END AS movie_era
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    (mh.title ILIKE '%adventure%' OR mh.production_year IS NULL)
ORDER BY 
    mh.production_year DESC NULLS LAST, 
    mh.title, 
    cd.actor_order
LIMIT 100;
