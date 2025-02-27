WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN aka_title at ON ml.linked_movie_id = at.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM 
        movie_hierarchy mh
),
average_cast AS (
    SELECT 
        mc.movie_id,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_size
    FROM 
        complete_cast mc
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id
),
movies_with_keywords AS (
    SELECT 
        mt.id,
        mt.title,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cast_info_count.count, 0) AS total_cast_members,
    mk.keywords,
    CASE 
        WHEN mwt.avg_cast_size IS NULL THEN 'No Data'
        ELSE CAST(mwt.avg_cast_size AS TEXT)
    END AS average_cast_size
FROM 
    top_movies tm
LEFT JOIN 
    (SELECT 
         movie_id, COUNT(*) AS count 
     FROM 
         cast_info 
     GROUP BY 
         movie_id) AS cast_info_count ON tm.movie_id = cast_info_count.movie_id
LEFT JOIN 
    average_cast mwt ON tm.movie_id = mwt.movie_id
LEFT JOIN 
    movies_with_keywords mk ON tm.movie_id = mk.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.title;
