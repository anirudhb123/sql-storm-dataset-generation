
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies_count,
        COUNT(DISTINCT c.person_role_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2020
        AND k.keyword LIKE '%Drama%'
    GROUP BY 
        t.title, t.production_year, a.name
),
ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        keywords,
        production_companies_count,
        cast_count,
        RANK() OVER (ORDER BY production_companies_count DESC, cast_count DESC) AS rank
    FROM 
        movie_details
)
SELECT 
    *
FROM 
    ranked_movies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, rank;
