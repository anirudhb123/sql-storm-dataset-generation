
WITH ranked_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(tc.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(tc.id) DESC) AS rank
    FROM 
        aka_title mt
        LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
        LEFT JOIN cast_info tc ON cc.subject_id = tc.person_id
    GROUP BY 
        mt.title, mt.production_year
),
filtered_movies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.total_cast
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
),
movie_details AS (
    SELECT 
        fm.title,
        fm.production_year,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        filtered_movies fm
        LEFT JOIN movie_companies mc ON fm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
        LEFT JOIN company_name cn ON mc.company_id = cn.id
        LEFT JOIN movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)
        LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.title, fm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_names, 'No Companies') AS company_names,
    COALESCE(md.keywords, 'No Keywords') AS keywords
FROM 
    movie_details md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC, 
    md.title;
