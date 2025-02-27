WITH movie_summary AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name SEPARATOR ', ') AS aka_names,
        GROUP_CONCAT(DISTINCT ci.person_role_id ORDER BY ci.nr_order SEPARATOR ', ') AS roles,
        GROUP_CONCAT(DISTINCT cn.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT kw.keyword SEPARATOR ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

role_summary AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT ci.role_id) AS distinct_roles
    FROM 
        movie_summary mt
    JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.movie_id
)

SELECT 
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.aka_names,
    rs.total_cast,
    rs.distinct_roles,
    ms.companies,
    ms.keywords
FROM 
    movie_summary ms
JOIN 
    role_summary rs ON ms.movie_id = rs.movie_id
ORDER BY 
    ms.production_year DESC, 
    ms.movie_title;
