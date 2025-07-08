
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(NULLIF(com.name, ''), 'Unknown') AS company_name,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS ranking
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name com ON mc.company_id = com.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year, com.name
),
banned_titles AS (
    SELECT 
        mt.id, 
        mt.title 
    FROM 
        aka_title mt
    WHERE 
        mt.title ILIKE '%banned%'
),
filtered_movies AS (
    SELECT 
        mh.*,
        (SELECT COUNT(*) FROM cast_info c WHERE c.movie_id = mh.movie_id AND c.note IS NOT NULL) AS cast_count,
        (SELECT LISTAGG(DISTINCT kw.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword kw ON mk.keyword_id = kw.id 
         WHERE mk.movie_id = mh.movie_id) AS keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        banned_titles bt ON mh.movie_id = bt.id
    WHERE 
        bt.id IS NULL
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.company_name,
    f.ranking,
    f.cast_count,
    COALESCE(f.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN f.cast_count > 10 THEN 'Popular'
        WHEN f.cast_count IS NULL THEN 'No Cast Info'
        ELSE 'Less Popular'
    END AS popularity_status
FROM 
    filtered_movies f
WHERE 
    f.ranking <= 5
ORDER BY 
    f.production_year DESC, 
    f.ranking ASC;
