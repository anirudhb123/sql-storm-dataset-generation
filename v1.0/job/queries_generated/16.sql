WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info c ON at.id = c.movie_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        at.id, at.title, at.production_year
),
latest_movies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        ranked_movies 
    WHERE 
        rn <= 10
),
movie_details AS (
    SELECT 
        lm.title,
        lm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        latest_movies lm
    LEFT JOIN 
        movie_keyword mk ON lm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        movie_companies mc ON lm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        lm.title, lm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.companies,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = md.title)) AS total_cast,
    (SELECT COUNT(DISTINCT pi.person_id) FROM person_info pi WHERE pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth_date')) AS total_birthday_info
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, md.title;
