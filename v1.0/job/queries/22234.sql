WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name DESC), '{}') AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast_size,
        COUNT(ci.id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY mt.id, mt.title, mt.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_info_with_types AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT (it.info || ':' || mi.info), '; ') AS movie_info
    FROM 
        movie_info mi
    JOIN info_type it ON mi.info_type_id = it.id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mit.movie_info, 'No Info') AS movie_info,
    rm.cast_count,
    rm.rank_by_cast_size,
    CASE 
        WHEN rm.rank_by_cast_size = 1 THEN 'Top Cast Movie'
        ELSE 'Regular Movie'
    END AS movie_rank_category
FROM 
    ranked_movies rm
LEFT JOIN movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN movie_info_with_types mit ON rm.movie_id = mit.movie_id
WHERE 
    rm.rank_by_cast_size <= 5 AND 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC,
    rm.rank_by_cast_size ASC;

