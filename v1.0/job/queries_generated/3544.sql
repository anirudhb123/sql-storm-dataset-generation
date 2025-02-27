WITH movie_summary AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN mc.company_id IS NOT NULL THEN 1 ELSE 0 END) AS company_backed_count
    FROM
        aka_title at
        LEFT JOIN cast_info c ON at.id = c.movie_id
        LEFT JOIN movie_companies mc ON at.id = mc.movie_id
    WHERE
        at.production_year BETWEEN 2000 AND 2020
    GROUP BY
        at.id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
detailed_movie_info AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.company_backed_count,
        COALESCE(ks.keywords, 'No keywords') AS keywords
    FROM 
        movie_summary ms
        LEFT JOIN keyword_summary ks ON ms.id = ks.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.cast_count,
    dmi.company_backed_count,
    dmi.keywords,
    ROW_NUMBER() OVER (PARTITION BY dmi.production_year ORDER BY dmi.cast_count DESC) AS rank_by_cast_count
FROM 
    detailed_movie_info dmi
WHERE 
    dmi.cast_count > 0
ORDER BY 
    dmi.production_year, dmi.cast_count DESC;
