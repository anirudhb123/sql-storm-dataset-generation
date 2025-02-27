WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mtl.linked_movie_id, 0) AS linked_movie_id
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mtl ON mt.id = mtl.movie_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(mtl.linked_movie_id, 0)
    FROM 
        aka_title mt
    JOIN 
        movie_link mtl ON mt.id = mtl.movie_id
    JOIN 
        movie_hierarchy mh ON mh.linked_movie_id = mt.id
),

movie_keywords AS (
    SELECT 
        mt.id AS movie_id,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
),

cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),

ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mk.keywords, '{}') AS keywords,
        COALESCE(cd.num_cast_members, 0) AS num_cast,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY cd.num_cast_members DESC) AS rank_by_cast
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
)

SELECT 
    r.title,
    r.production_year,
    r.keywords,
    r.num_cast,
    CASE 
        WHEN r.rank_by_cast = 1 THEN 'Top Cast'
        WHEN r.num_cast > 5 THEN 'Large Ensemble'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    ranked_movies r
WHERE 
    r.production_year >= 2000 
    AND r.num_cast > 0
ORDER BY 
    r.production_year DESC, r.rank_by_cast;
