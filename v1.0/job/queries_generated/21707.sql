WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast,
        ARRAY_AGG(DISTINCT COALESCE(a.name, 'Unknown')) AS cast_names
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL 
    GROUP BY 
        t.id, t.title, t.production_year 
    HAVING 
        COUNT(ci.person_id) > 0
),
latest_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        cast_count,
        rank_by_cast,
        cast_names 
    FROM 
        ranked_movies 
    WHERE 
        rank_by_cast <= 5
),
movies_with_info AS (
    SELECT 
        lm.movie_id,
        lm.title,
        lm.production_year,
        lm.cast_count,
        lm.cast_names,
        COALESCE(mi.info, 'N/A') AS additional_info
    FROM 
        latest_movies lm
    LEFT JOIN 
        movie_info mi ON lm.movie_id = mi.movie_id 
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Trivia%')
),
final_output AS (
    SELECT 
        mw.info_id,
        mw.title,
        mw.production_year,
        mw.cast_count,
        mw.cast_names,
        mw.additional_info,
        CASE 
            WHEN mw.cast_count > 10 THEN 'Large Cast'
            WHEN mw.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size_category,
        CASE 
            WHEN mw.additional_info IS NULL THEN 'No Additional Information'
            ELSE mw.additional_info
        END AS info_status
    FROM 
        movies_with_info mw
)
SELECT 
    fo.*,
    COALESCE(mci.note, 'No Company Info') AS company_note
FROM 
    final_output fo
LEFT JOIN 
    movie_companies mc ON mc.movie_id = fo.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = fo.movie_id AND mi.note IS NOT NULL
LEFT JOIN 
    movie_info_idx mii ON mii.movie_id = fo.movie_id
WHERE 
    fo.production_year BETWEEN 2000 AND 2023
    AND (mii.info LIKE '%Academy%' OR mii.info IS NULL)
ORDER BY 
    fo.production_year DESC, fo.cast_count DESC;
