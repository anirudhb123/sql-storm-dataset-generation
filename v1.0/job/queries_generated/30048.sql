WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
ActorRole AS (
    SELECT 
        ci.movie_id,
        ka.name AS actor_name,
        rt.role AS role_title,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ka ON ci.person_id = ka.person_id
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
),
TitleKeywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        aka_title AS mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.id
)
SELECT 
    mh.movie_id,
    mh.title,
    ARRAY_AGG(DISTINCT ak.actor_name ORDER BY ak.actor_order) AS cast,
    COALESCE(tk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mh.level = 0 THEN 'Top Level'
        WHEN mh.level <= 2 THEN 'Mid Level'
        ELSE 'Deep'
    END AS hierarchy_level
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    ActorRole AS ak ON mh.movie_id = ak.movie_id
LEFT JOIN 
    TitleKeywords AS tk ON mh.movie_id = tk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.level, tk.keywords
ORDER BY 
    mh.production_year DESC, mh.title;
