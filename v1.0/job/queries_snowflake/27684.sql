
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        pt.kind AS production_type,
        COUNT(ca.id) AS cast_count,
        LISTAGG(DISTINCT na.name, ', ') WITHIN GROUP (ORDER BY na.name) AS cast_members
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type pt ON mc.company_type_id = pt.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        aka_name na ON ca.person_id = na.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, c.name, pt.kind
),
ranked_movies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    movie_keyword,
    company_name,
    production_type,
    cast_count,
    cast_members
FROM 
    ranked_movies
WHERE 
    rank <= 5
ORDER BY 
    production_year, rank;
