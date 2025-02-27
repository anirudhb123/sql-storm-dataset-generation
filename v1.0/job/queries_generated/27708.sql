WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        p.name AS person_name,
        r.role AS person_role,
        COUNT(DISTINCT ci.id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, p.name, r.role
),
Ranking AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS year_rank
    FROM 
        MovieDetails
)
SELECT 
    title_id,
    movie_title,
    production_year,
    movie_keyword,
    company_name,
    person_name,
    person_role,
    cast_count
FROM 
    Ranking
WHERE 
    year_rank <= 5
ORDER BY 
    production_year DESC, cast_count DESC;
