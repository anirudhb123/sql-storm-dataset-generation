WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id 
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),

cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS full_cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id 
    GROUP BY 
        ci.movie_id
),

keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        cs.cast_count,
        cs.full_cast_names,
        ks.keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_summary cs ON m.id = cs.movie_id
    LEFT JOIN 
        keyword_summary ks ON m.id = ks.movie_id 
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.cast_count, 0) AS total_cast,
    md.full_cast_names,
    md.keywords,
    CASE 
        WHEN md.production_year IS NULL THEN 'Unknown' 
        ELSE CONCAT('Year: ', md.production_year) 
    END AS year_info,
    ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.title) AS row_num,
    COUNT(1) OVER (PARTITION BY md.production_year) AS total_movies_in_year
FROM 
    movie_details md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC,
    md.title;

This query uses several advanced SQL constructs to benchmark performance, including:

1. **CTEs**: The use of recursive CTEs to create a hierarchy of movies related through links.
2. **Aggregation**: Summarizing casts and keywords for each movie using `COUNT` and `STRING_AGG`.
3. **Outer Joins**: Obtaining casting and keyword information even if they may be absent.
4. **Window Functions**: Using `ROW_NUMBER()` and `COUNT()` to analyze movie distribution by year.
5. **NULL Logic**: Handling potential null values elegantly with `COALESCE`.
6. **String Expressions**: Utilizing `CONCAT` to format output neatly. 

The query aims to fetch detailed movie information while accounting for performance using complex joins and aggregations.
