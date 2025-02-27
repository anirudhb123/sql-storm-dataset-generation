WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
top_movies AS (
    SELECT 
        title, 
        production_year
    FROM 
        ranked_movies
    WHERE 
        rn <= 5
),
company_info AS (
    SELECT 
        m.movie_id,
        COALESCE(c.name, 'Unknown') AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    LEFT JOIN 
        company_name c ON m.company_id = c.id
    LEFT JOIN 
        company_type ct ON m.company_type_id = ct.id
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        ci.company_name,
        ci.company_type
    FROM 
        top_movies tm
    LEFT JOIN 
        complete_cast cc ON tm.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
    LEFT JOIN 
        company_info ci ON cc.movie_id = ci.movie_id
),
average_years AS (
    SELECT 
        production_year,
        AVG(cast_count) AS avg_cast_count
    FROM 
        ranked_movies
    GROUP BY 
        production_year
)

SELECT 
    md.title, 
    md.production_year,
    md.company_name,
    md.company_type,
    CASE 
        WHEN avg.avg_cast_count IS NOT NULL THEN 
            LEAST(5, ROUND((COUNT(md.title) * 1.0 / avg.avg_cast_count), 2))
        ELSE 
            NULL
    END AS cast_ratio
FROM 
    movie_details md
LEFT JOIN 
    average_years avg ON md.production_year = avg.production_year
GROUP BY 
    md.title, 
    md.production_year, 
    md.company_name, 
    md.company_type, 
    avg.avg_cast_count
ORDER BY 
    md.production_year DESC, 
    md.title;
