WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id
),
cast_age AS (
    SELECT 
        ci.movie_id,
        AVG(EXTRACT(YEAR FROM age(pi.birth_date))) AS avg_age
    FROM 
        cast_info AS ci
    JOIN 
        person_info AS pi ON ci.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
    GROUP BY 
        ci.movie_id
),
final_data AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_names,
        md.cast_count,
        COALESCE(ca.avg_age, 0) AS avg_cast_age
    FROM 
        movie_data AS md
    LEFT JOIN 
        cast_age AS ca ON md.id = ca.movie_id
)
SELECT 
    movie_title,
    production_year,
    company_names,
    cast_count,
    avg_cast_age
FROM 
    final_data
WHERE 
    cast_count > 5
ORDER BY 
    production_year DESC, cast_count DESC;
