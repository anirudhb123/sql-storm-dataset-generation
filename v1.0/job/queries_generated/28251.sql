WITH movie_info_summary AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, c.name
),
high_cast_movies AS (
    SELECT 
        movie_title, 
        production_year,
        company_name,
        keywords,
        cast_count 
    FROM
        movie_info_summary
    WHERE 
        cast_count > 5
)
SELECT 
    hcm.movie_title, 
    hcm.production_year,
    hcm.company_name, 
    hcm.keywords, 
    hcm.cast_count,
    char_length(hcm.keywords) AS keyword_length
FROM 
    high_cast_movies hcm
ORDER BY 
    hcm.production_year DESC, 
    hcm.cast_count DESC;
