WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3  -- limit hierarchy depth
),

movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

actors_info AS (
    SELECT 
        p.id AS person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movies_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        p.id, ak.name
),

final_selection AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mk.keywords,
        ai.actor_name,
        ai.movies_count,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        actors_info ai ON mh.movie_id = ai.person_id
    WHERE 
        mh.production_year BETWEEN 2000 AND 2023
)

SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.keywords,
    fs.actor_name,
    fs.movies_count,
    fs.rank
FROM 
    final_selection fs
WHERE 
    fs.rank <= 5  -- Display top 5 for each level
ORDER BY 
    fs.production_year DESC, fs.rank;
