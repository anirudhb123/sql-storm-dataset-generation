WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.name_pcode_cf AS actor_code,
        k.keyword AS movie_keyword,
        c.kind AS company_kind,
        GROUP_CONCAT(DISTINCT c.name) AS production_companies,
        COUNT(DISTINCT ci.id) AS total_cast_members
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, ak.name, k.keyword, c.kind
),
average_cast AS (
    SELECT 
        AVG(total_cast_members) AS avg_cast_members
    FROM 
        movie_details
),
top_movies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast_members,
        CASE 
            WHEN total_cast_members > (SELECT avg_cast_members FROM average_cast) THEN 'Above Average'
            ELSE 'Below Average' 
        END AS cast_size_comparison
    FROM 
        movie_details
    ORDER BY 
        total_cast_members DESC
    LIMIT 10
)
SELECT 
    movie_title,
    production_year,
    total_cast_members,
    cast_size_comparison,
    GROUP_CONCAT(DISTINCT actor_name) AS actors,
    GROUP_CONCAT(DISTINCT movie_keyword) AS keywords,
    GROUP_CONCAT(DISTINCT actor_code) AS actor_codes,
    GROUP_CONCAT(DISTINCT company_kind) AS companies
FROM 
    top_movies
JOIN 
    movie_details ON top_movies.movie_title = movie_details.movie_title
GROUP BY 
    movie_title, production_year, total_cast_members, cast_size_comparison
ORDER BY 
    production_year DESC;
