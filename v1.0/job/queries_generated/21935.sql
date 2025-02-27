WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        COALESCE(kt.keyword, 'Unknown') AS keyword,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Year'
            ELSE m.production_year::text
        END AS production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS row_num
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        title m ON t.id = m.id
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        mc.movie_id,
        mt.title,
        COALESCE(mkc.keyword, 'Missing') AS keyword,
        COALESCE(mt.production_year, 'N/A') AS production_year,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(mt.production_year, 'N/A') ORDER BY mc.movie_id) + (SELECT MAX(row_num) FROM movie_hierarchy) AS row_num
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_keyword mkc ON mt.id = mkc.movie_id
    JOIN 
        keyword mk ON mkc.keyword_id = mk.id
    JOIN 
        complete_cast mc ON mt.id = mc.movie_id
    WHERE 
        ml.link_type_id IS NOT NULL
),
movie_info_summary AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.keyword,
        mh.production_year,
        COUNT(ci.role_id) AS total_roles,
        COUNT(DISTINCT ci.person_id) AS unique_actors
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.keyword, mh.production_year
)
SELECT 
    mis.movie_id,
    mis.title,
    mis.keyword,
    mis.production_year,
    mis.total_roles,
    mis.unique_actors,
    CASE 
        WHEN mis.total_roles > 5 THEN 'Ensemble Cast'
        WHEN mis.unique_actors > 3 THEN 'Many actors'
        ELSE 'Few Actors'
    END AS cast_description
FROM 
    movie_info_summary mis
WHERE 
    mis.production_year <> 'N/A'
    AND mis.production_year NOT IN ('2023', '2022')
ORDER BY 
    mis.production_year DESC, 
    mis.unique_actors DESC;

-- Optional string manipulation to demonstrate nuanced SQL behavior
SELECT 
    movie_id, 
    title, 
    LENGTH(keyword) AS keyword_length,
    CASE 
        WHEN LENGTH(keyword) % 2 = 0 THEN 'Even Length Keyword'
        ELSE 'Odd Length Keyword'
    END AS keyword_parity
FROM 
    movie_info_summary;
