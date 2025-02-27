WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        c.nr_order,
        COALESCE(p.info, 'No Info') AS personal_info
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
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
    tt.title_id,
    tt.title,
    tt.production_year,
    ai.name AS actor_name,
    ai.nr_order,
    mk.keywords,
    CASE 
        WHEN ai.personal_info IS NULL THEN 'No Personal Info Available'
        WHEN ai.personal_info = 'No Info' THEN 'No Additional Info Provided'
        ELSE ai.personal_info
    END AS personal_info_display,
    COUNT(DISTINCT m.movie_id) OVER (PARTITION BY tt.production_year) AS movies_in_year,
    (SELECT COUNT(*) FROM title t2 WHERE t2.production_year = tt.production_year) AS total_titles_in_year
FROM 
    ranked_titles tt
LEFT JOIN 
    actor_info ai ON tt.title_id = ai.movie_id
LEFT JOIN 
    movie_keywords mk ON tt.title_id = mk.movie_id
WHERE 
    tt.year_rank <= 5 
    OR (ai.nr_order IS NOT NULL AND ai.nr_order < 3) 
    OR (mk.keywords IS NOT NULL AND mk.keywords LIKE '%Horror%')
ORDER BY 
    tt.production_year DESC,
    tt.title;
