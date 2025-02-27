WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(mk.keyword, 'Uncategorized') AS movie_keyword,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        'Sequel of: ' || mu.movie_title AS movie_title,
        mu.production_year,
        COALESCE(mk.keyword, 'Uncategorized'),
        h.level + 1
    FROM 
        movie_hierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title mu ON ml.linked_movie_id = mu.id
    LEFT JOIN 
        movie_keyword mk ON mu.id = mk.movie_id
),

aggregated_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),

ranked_movies AS (
    SELECT 
        h.movie_id,
        h.movie_title,
        h.production_year,
        h.movie_keyword,
        ac.actors,
        ac.total_cast,
        ROW_NUMBER() OVER (PARTITION BY h.movie_keyword ORDER BY h.production_year DESC) AS movie_rank
    FROM 
        movie_hierarchy h
    LEFT JOIN 
        aggregated_cast ac ON h.movie_id = ac.movie_id
)

SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.movie_keyword,
    rm.actors,
    rm.total_cast,
    CASE 
        WHEN rm.movie_rank = 1 THEN 'Top Ranked'
        WHEN rm.total_cast IS NULL THEN 'No Cast Info'
        ELSE 'Lower Rank'
    END AS rank_category
FROM 
    ranked_movies rm
WHERE 
    rm.movie_rank <= 5
    AND (rm.movie_keyword LIKE 'Horror%' OR rm.movie_keyword LIKE 'Action%')
ORDER BY 
    rm.movie_keyword, rm.production_year DESC;

-- Additional Cases
WITH movie_info_subset AS (
    SELECT 
        m.id,
        mi.info AS movie_data
    FROM 
        aka_title m
    JOIN 
        movie_info_idx mi ON m.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%rating%')
),
missing_keywords AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year < 2000
    GROUP BY 
        m.id
    HAVING 
        COUNT(mk.keyword) = 0
)

SELECT 
    m.id,
    m.title,
    COALESCE(mks.keyword_count, 0) AS missing_keywords_count,
    CASE 
        WHEN m.info IS NULL THEN 'No Info Available'
        ELSE 'Info Present'
    END AS info_status
FROM 
    aka_title m
LEFT JOIN 
    missing_keywords mks ON m.id = mks.movie_id
LEFT JOIN 
    movie_info_subset mis ON m.id = mis.id
WHERE 
    m.production_year > 1990
    AND (mis.movie_data IS NOT NULL OR mks.keyword_count IS NOT NULL)
ORDER BY 
    m.title;
