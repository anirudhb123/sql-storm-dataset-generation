WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           1 AS level
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT mt.id AS movie_id,
           mt.title,
           mt.production_year,
           mh.level + 1
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
),

popular_titles AS (
    SELECT mt.title,
           COUNT(cc.id) AS cast_count
    FROM aka_title mt
    JOIN cast_info cc ON mt.id = cc.movie_id
    GROUP BY mt.title
    HAVING COUNT(cc.id) > 5
),

company_info AS (
    SELECT co.name AS company_name,
           ct.kind AS company_type,
           mc.movie_id
    FROM movie_companies mc
    LEFT JOIN company_name co ON mc.company_id = co.id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    WHERE co.country_code IS NOT NULL
    AND ct.kind LIKE '%Production%'
),

keyword_summary AS (
    SELECT mt.production_year,
           k.keyword AS keywords,
           COUNT(mk.movie_id) AS keyword_count
    FROM aka_title mt
    JOIN movie_keyword mk ON mt.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mt.production_year, k.keyword
    HAVING COUNT(mk.movie_id) > 3
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(NULLIF(p.cast_count, 0), 'No Cast Data') AS cast_data,
    COALESCE(ci.company_name, 'Independent') AS production_company,
    COALESCE(ks.keywords, 'No Keywords') AS keywords
FROM movie_hierarchy mh
LEFT JOIN popular_titles p ON mh.title = p.title
LEFT JOIN company_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN keyword_summary ks ON mh.production_year = ks.production_year
ORDER BY mh.production_year DESC, mh.title ASC
FETCH FIRST 100 ROWS ONLY;

