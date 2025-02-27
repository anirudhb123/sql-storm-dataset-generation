WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        ct.id AS movie_id,
        ct.title,
        ct.production_year,
        mh.depth + 1
    FROM 
        aka_title ct
    INNER JOIN 
        movie_hierarchy mh ON ct.episode_of_id = mh.movie_id
),
cast_aggregates AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
keyword_aggregates AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ca.total_cast,
        ca.cast_names,
        ka.keywords,
        row_number() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC) AS year_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_aggregates ca ON mh.movie_id = ca.movie_id
    LEFT JOIN 
        keyword_aggregates ka ON mh.movie_id = ka.movie_id
),
final_selection AS (
    SELECT 
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_names,
        md.keywords,
        CASE 
            WHEN md.production_year IS NULL THEN 'Unknown Year'
            WHEN md.year_rank <= 5 THEN 'Top Production'
            ELSE 'Classic'
        END AS genre_category
    FROM 
        movie_details md
    WHERE 
        (md.production_year >= 2000 OR md.total_cast IS NULL)
        AND (md.keywords ILIKE '%action%' OR md.keywords IS NULL)
)
SELECT 
    fs.title,
    fs.production_year,
    fs.total_cast,
    fs.cast_names,
    fs.keywords,
    fs.genre_category,
    COALESCE(fs.cast_names, 'No Cast Available') AS cast_display,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = fs.movie_id AND mi.info_type_id = 1) AS info_count
FROM 
    final_selection fs
WHERE 
    UPPER(fs.genre_category) LIKE '%PRODUCTION%'
ORDER BY 
    fs.production_year DESC,
    fs.total_cast DESC;
