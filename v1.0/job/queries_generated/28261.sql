WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        title AS t
    JOIN 
        movie_companies AS mc ON mc.movie_id = t.id
    JOIN 
        company_name AS cn ON cn.id = mc.company_id 
    JOIN 
        cast_info AS ci ON ci.movie_id = t.id
    JOIN 
        aka_name AS an ON an.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS kw ON kw.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
),

person_data AS (
    SELECT 
        a.id AS person_id,
        a.name AS aka_name,
        p.gender,
        GROUP_CONCAT(DISTINCT pi.info) AS personal_info
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON ci.person_id = a.person_id
    JOIN 
        person_info AS pi ON pi.person_id = a.person_id
    GROUP BY 
        a.id, a.name, p.gender
),

joined_data AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_names,
        md.keywords,
        pd.aka_name,
        pd.gender,
        pd.personal_info
    FROM 
        movie_data AS md
    JOIN 
        person_data AS pd ON pd.aka_name IN (SELECT name FROM aka_name WHERE person_id IN (SELECT person_id FROM cast_info WHERE movie_id = md.movie_id))
)

SELECT 
    jd.title,
    jd.production_year,
    jd.cast_names,
    jd.keywords,
    jd.aka_name,
    jd.gender,
    jd.personal_info
FROM 
    joined_data AS jd
WHERE 
    jd.production_year > 2000
ORDER BY 
    jd.production_year DESC, jd.title;
