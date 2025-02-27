WITH RECURSIVE CTE_Movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        depth + 1
    FROM 
        aka_title m
    INNER JOIN movie_link ml ON m.id = ml.movie_id
    INNER JOIN CTE_Movies cm ON ml.linked_movie_id = cm.movie_id
),

Filtered_Cast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        COALESCE(p.gender, 'U') AS gender,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    LEFT JOIN name p ON ci.person_id = p.id
    WHERE 
        ci.nr_order IS NOT NULL
),

Genres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kt.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN keyword kt ON mt.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
),

Main_Query AS (
    SELECT 
        cm.movie_id,
        cm.title,
        cm.production_year,
        CAST(SUM(CASE WHEN fc.gender = 'F' THEN 1 ELSE 0 END) AS INTEGER) AS female_cast_count,
        CAST(SUM(CASE WHEN fc.gender = 'M' THEN 1 ELSE 0 END) AS INTEGER) AS male_cast_count,
        STRING_AGG(DISTINCT g.keywords, '; ') AS all_keywords,
        COALESCE(COUNT(m.id) FILTER (WHERE m.id IS NOT NULL), 0) AS total_movies_linked
    FROM 
        CTE_Movies cm
    LEFT JOIN 
        Filtered_Cast fc ON cm.movie_id = fc.movie_id
    LEFT JOIN 
        Genres g ON cm.movie_id = g.movie_id
    LEFT JOIN 
        movie_link ml ON cm.movie_id = ml.movie_id
    LEFT JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    GROUP BY 
        cm.movie_id, cm.title, cm.production_year
)

SELECT 
    mq.movie_id,
    mq.title,
    mq.production_year,
    mq.female_cast_count,
    mq.male_cast_count,
    mq.all_keywords,
    CASE 
        WHEN mq.total_movies_linked > 5 THEN 'Popular'
        WHEN mq.total_movies_linked = 0 THEN 'Standalone'
        ELSE 'Moderate'
    END AS movie_category
FROM 
    Main_Query mq
WHERE  
    mq.production_year >= 2000
ORDER BY 
    mq.production_year DESC,
    mq.female_cast_count DESC,
    mq.male_cast_count DESC;
