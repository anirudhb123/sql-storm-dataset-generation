
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count,
        DENSE_RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        movie_details
),
highest_rated_movies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.keyword,
        m.cast_count
    FROM 
        top_movies m
    WHERE 
        m.rank = 1
),
movie_info_details AS (
    SELECT 
        mi.movie_id,
        LISTAGG(mi.info, ', ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
final_report AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        h.keyword,
        h.cast_count,
        COALESCE(mid.info_details, 'No Info') AS additional_info
    FROM 
        highest_rated_movies h
    LEFT JOIN 
        movie_info_details mid ON h.movie_id = mid.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.keyword,
    fr.additional_info,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = fr.movie_id AND ci.person_role_id IS NOT NULL) AS unique_roles_casted,
    CASE 
        WHEN fr.cast_count > 5 THEN 'Large Ensemble' 
        WHEN fr.cast_count BETWEEN 3 AND 5 THEN 'Medium Ensemble' 
        ELSE 'Simple Cast' 
    END AS cast_size_category
FROM 
    final_report fr
WHERE 
    fr.production_year >= 2000
ORDER BY 
    fr.production_year DESC, 
    fr.cast_count DESC;
