WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT cast_id) DESC) AS rank,
        COUNT(DISTINCT ca.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT *
    FROM ranked_movies
    WHERE rank <= 5
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
),
movie_info_combined AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CASE 
                      WHEN it.info = 'Tagline' THEN mi.info 
                      ELSE NULL 
                   END, ', ') AS taglines,
        STRING_AGG(CASE 
                      WHEN it.info = 'Summary' THEN mi.info 
                      ELSE NULL 
                   END, ', ') AS summaries
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title AS movie_title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mic.taglines, 'No taglines') AS taglines,
    COALESCE(mic.summaries, 'No summaries') AS summaries,
    COALESCE(CAST(SUM(CASE WHEN ca.person_role_id IS NULL THEN 1 ELSE 0 END) AS INTEGER), 0) AS missing_roles
FROM 
    top_movies tm
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_combined mic ON tm.movie_id = mic.movie_id
LEFT JOIN 
    cast_info ca ON tm.movie_id = ca.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, tm.title;

WITH NULL_cases AS (
    SELECT 
        c.movie_id,
        c.person_id,
        c.note,
        CASE WHEN c.note IS NULL THEN 'No Note Provided' ELSE c.note END AS note_info,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS order_num
    FROM 
        cast_info c
    WHERE 
        c.note IS NULL OR c.note ILIKE '%important%'
)
SELECT 
    COUNT(*) AS null_note_count,
    COUNT(DISTINCT movie_id) AS unique_movies_with_null,
    AVG(CASE WHEN order_num = 1 THEN 1 ELSE 0 END) AS first_actor_null_note_ratio
FROM 
    NULL_cases;

SELECT 
    comp.kind AS company_kind,
    COUNT(DISTINCT mc.movie_id) AS movies_count,
    MAX(CASE WHEN c.note IS NOT NULL THEN c.note ELSE 'No note' END) AS example_note
FROM 
    movie_companies mc
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type comp ON mc.company_type_id = comp.id
LEFT JOIN 
    movie_info mi ON mc.movie_id = mi.movie_id AND mi.note IS NOT NULL
LEFT JOIN 
    cast_info c ON mc.movie_id = c.movie_id
GROUP BY 
    comp.kind
HAVING 
    COUNT(DISTINCT mc.movie_id) > 1
ORDER BY 
    movies_count DESC;
