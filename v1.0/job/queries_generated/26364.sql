WITH movie_summary AS (
    SELECT 
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        MIN(cc.nr_order) AS first_cast_order,
        MAX(cc.nr_order) AS last_cast_order
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        t.title, t.production_year
),
studio_summary AS (
    SELECT
        m.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM
        movie_companies m
    JOIN 
        company_name cn ON cn.id = m.company_id
    JOIN 
        company_type ct ON ct.id = m.company_type_id
    GROUP BY
        m.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.aka_names,
    ms.keywords,
    ms.total_cast,
    ms.first_cast_order,
    ms.last_cast_order,
    ss.companies,
    ss.company_types
FROM 
    movie_summary ms
LEFT JOIN 
    studio_summary ss ON ss.movie_id = ms.movie_id
WHERE 
    ms.production_year BETWEEN 2000 AND 2020
ORDER BY 
    ms.production_year DESC, 
    ms.total_cast DESC;

