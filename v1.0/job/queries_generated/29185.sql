WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        c.country_code,
        kc.keyword AS movie_keyword,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        COUNT(DISTINCT mi.info) AS total_movie_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.title, t.production_year, c.name, c.country_code, kc.keyword
),
top_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_name,
        md.country_code,
        md.movie_keyword,
        md.aka_names,
        md.total_cast,
        md.total_movie_info,
        RANK() OVER (ORDER BY md.total_cast DESC) AS cast_rank,
        RANK() OVER (ORDER BY md.total_movie_info DESC) AS info_rank
    FROM 
        movie_details md
)
SELECT 
    movie_title,
    production_year,
    company_name,
    country_code,
    movie_keyword,
    aka_names,
    total_cast,
    total_movie_info,
    CASE 
        WHEN cast_rank <= 10 THEN 'Top 10 by Cast'
        ELSE 'Other'
    END AS cast_category,
    CASE 
        WHEN info_rank <= 10 THEN 'Top 10 by Info'
        ELSE 'Other'
    END AS info_category
FROM 
    top_movies
ORDER BY 
    production_year DESC, total_cast DESC;
