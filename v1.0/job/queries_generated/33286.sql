WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000 

    UNION ALL 

    SELECT 
        mc.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link mc ON mh.movie_id = mc.movie_id
    JOIN 
        aka_title mt ON mc.linked_movie_id = mt.id
),

TopCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),

MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(tc.actor_name, 'No Actor') AS primary_actor,
        mh.level,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        TopCast tc ON mh.movie_id = tc.movie_id AND tc.actor_rank = 1
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, tc.actor_name, mh.level
)

SELECT 
    md.*,
    CASE 
        WHEN md.level = 1 THEN 'Main Feature'
        WHEN md.level > 1 THEN 'Linked Feature'
        ELSE 'Unknown Level'
    END AS feature_type
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 0
ORDER BY 
    md.production_year DESC, md.level ASC;
