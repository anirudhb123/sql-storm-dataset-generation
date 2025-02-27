WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assuming 1 represents movies
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title, 
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role,
        COUNT(ci.person_id) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        MAX(cir.actor_count) AS total_cast,
        STRING_AGG(DISTINCT cir.actor_name, ', ') AS cast_names,
        SUM(CASE WHEN cir.role = 'Director' THEN 1 ELSE 0 END) AS director_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastInfoWithRoles cir ON mh.movie_id = cir.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    md.director_count,
    CASE 
        WHEN md.director_count > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_director,
    NULLIF(md.total_cast, 0) AS non_zero_cast -- This would return NULL if total_cast == 0
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.total_cast DESC;

- This query constructs a recursive CTE to build a movie hierarchy, capturing a movie and its linked movies, and their respective levels.
- It aggregates casting information to count the total actors per movie and list their names. 
- It also counts the number of directors associated with these movies.
- The final selection filters movies produced from the year 2000 onwards, indicating if a director exists, and handles potential NULL values appropriately.
