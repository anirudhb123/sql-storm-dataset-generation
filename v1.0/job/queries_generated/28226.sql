WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        GROUP_CONCAT(DISTINCT c.name) AS cast,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT co.name) AS companies
    FROM 
        aka_title AS t
    JOIN 
        aka_name AS ak ON ak.person_id = t.id
    JOIN 
        cast_info AS ci ON ci.movie_id = t.id
    JOIN 
        name AS c ON c.id = ci.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name AS co ON co.id = mc.company_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id
),
title_stats AS (
    SELECT 
        production_year,
        COUNT(DISTINCT title_id) AS total_movies,
        COUNT(DISTINCT aliases) AS total_aliases,
        COUNT(DISTINCT cast) AS total_cast,
        COUNT(DISTINCT keywords) AS total_keywords,
        COUNT(DISTINCT companies) AS total_companies
    FROM 
        movie_details
    GROUP BY 
        production_year
)
SELECT 
    s.production_year,
    s.total_movies,
    s.total_aliases,
    s.total_cast,
    s.total_keywords,
    s.total_companies,
    (s.total_movies * 1.0 / NULLIF(SUM(s.total_movies) OVER (), 0)) * 100 AS percentage_of_total
FROM 
    title_stats AS s
ORDER BY 
    s.production_year DESC;
