WITH 
    ranked_movies AS (
        SELECT 
            t.id AS movie_id,
            t.title,
            t.production_year,
            COUNT(DISTINCT ci.person_id) AS cast_count,
            ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
        FROM 
            aka_title t
        LEFT JOIN 
            cast_info ci ON t.id = ci.movie_id
        GROUP BY 
            t.id, t.title, t.production_year
    ),
    filtered_titles AS (
        SELECT 
            rm.movie_id,
            rm.title,
            rm.production_year,
            rm.cast_count,
            CASE 
                WHEN rm.production_year < 2000 THEN 'Classic'
                WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
                ELSE 'Recent'
            END AS era
        FROM 
            ranked_movies rm
        WHERE 
            rm.cast_count > 5
    ),
    movie_keywords AS (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    )
SELECT
    ft.title,
    ft.production_year,
    ft.cast_count,
    ft.era,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    COUNT(DISTINCT lc.linked_movie_id) AS linked_movie_count
FROM 
    filtered_titles ft
LEFT JOIN 
    movie_companies mc ON ft.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
LEFT JOIN 
    movie_link lc ON ft.movie_id = lc.movie_id
LEFT JOIN 
    movie_keywords mk ON ft.movie_id = mk.movie_id
GROUP BY 
    ft.movie_id, ft.title, ft.production_year, ft.cast_count, ft.era, mk.keywords, cn.name
HAVING 
    ft.era = 'Modern' AND 
    COUNT(DISTINCT ci.person_id) OVER (PARTITION BY ft.production_year) > 10
ORDER BY 
    ft.production_year DESC,
    ft.cast_count DESC
LIMIT 50;
