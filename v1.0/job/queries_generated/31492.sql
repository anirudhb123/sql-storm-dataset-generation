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
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

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
),

movie_cast AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT ak.name) AS cast_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT mc.person_id) AS total_cast_members
    FROM 
        cast_info mc
    JOIN 
        aka_name ak ON mc.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    GROUP BY 
        mc.movie_id
),

featured_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mc.cast_names,
        mc.keyword_count,
        mc.total_cast_members,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, mc.keyword_count DESC) AS row_num
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_cast mc ON mh.movie_id = mc.movie_id
)

SELECT 
    f.title,
    f.production_year,
    f.cast_names,
    f.keyword_count,
    f.total_cast_members
FROM 
    featured_movies f
WHERE 
    f.row_num <= 10
ORDER BY 
    f.keyword_count DESC, f.production_year DESC;
