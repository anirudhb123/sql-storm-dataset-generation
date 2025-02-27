WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
movie_info_details AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords,
        MAX(CASE WHEN it.info = 'Synopsis' THEN mi.info END) AS synopsis
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),
movie_company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    mk.keywords,
    mcd.companies,
    rm.rank,
    COALESCE(mk.synopsis, 'No synopsis available') AS synopsis,
    CASE WHEN rm.rank < 5 THEN 'Top Rank Movie' ELSE 'Other' END AS ranking_category
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_info_details mk ON rm.movie_id = mk.movie_id
FULL OUTER JOIN 
    movie_company_details mcd ON rm.movie_id = mcd.movie_id
WHERE 
    rm.production_year IS NOT NULL
    AND (rm.production_year < 2000 OR mk.keywords IS NOT NULL)
ORDER BY 
    rm.rank,
    rm.production_year DESC NULLS LAST

UNION ALL

SELECT 
    'Unknown Movie' AS title,
    NULL AS production_year,
    NULL AS keywords,
    NULL AS companies,
    NULL AS rank,
    'No synopsis available' AS synopsis,
    'Unknown' AS ranking_category
WHERE NOT EXISTS (SELECT 1 FROM ranked_movies);
