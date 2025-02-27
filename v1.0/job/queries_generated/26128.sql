WITH movie_details AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        AVG(CAST(ci.nr_order AS FLOAT)) AS avg_cast_order,
        COUNT(DISTINCT ci.person_id) AS total_cast_members
    FROM
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY
        t.id
),
production_years AS (
    SELECT
        production_year,
        COUNT(*) AS total_movies,
        COUNT(DISTINCT movie_id) AS unique_movies,
        ARRAY_AGG(DISTINCT title ORDER BY title) AS titles
    FROM
        movie_details
    GROUP BY
        production_year
)
SELECT 
    py.production_year,
    py.total_movies,
    py.unique_movies,
    py.titles,
    md.avg_cast_order,
    md.total_cast_members
FROM
    production_years py
JOIN 
    (SELECT 
         production_year,
         AVG(avg_cast_order) AS avg_cast_order,
         SUM(total_cast_members) AS total_cast_members
     FROM 
         movie_details
     GROUP BY 
         production_year) md
ON 
    py.production_year = md.production_year
ORDER BY 
    py.production_year DESC;
