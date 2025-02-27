
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
most_casted_movie AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank = 1
),
movie_details AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ky.keyword,
        cn.name AS company_name,
        ci.role_id
    FROM 
        most_casted_movie m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ky ON mk.keyword_id = ky.id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    ARRAY_AGG(DISTINCT md.keyword) AS keywords,
    ARRAY_AGG(DISTINCT md.company_name) AS production_companies,
    COUNT(DISTINCT ci.role_id) AS unique_roles,
    STRING_AGG(DISTINCT CAST(ci.role_id AS TEXT), ', ') AS role_ids
FROM 
    movie_details md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
GROUP BY 
    md.title, md.production_year
ORDER BY 
    md.production_year DESC, COUNT(DISTINCT ci.role_id) DESC;
