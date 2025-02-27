WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        c.name AS company_name, 
        ct.kind AS company_type,
        t.production_year, 
        k.keyword AS movie_keyword
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword IS NOT NULL
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_aggregates AS (
    SELECT 
        md.movie_id,
        md.title,
        md.company_name,
        md.company_type,
        md.production_year,
        md.movie_keyword,
        cd.total_cast,
        cd.cast_names
    FROM 
        movie_details AS md
    LEFT JOIN 
        cast_details AS cd ON md.movie_id = cd.movie_id
)
SELECT 
    title,
    company_name,
    company_type,
    production_year,
    movie_keyword,
    total_cast,
    cast_names
FROM 
    movie_info_aggregates
ORDER BY 
    production_year DESC, 
    title ASC;
