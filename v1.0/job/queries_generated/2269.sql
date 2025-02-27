WITH movie_data AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        c.kind AS company_kind,
        p.gender,
        COUNT(DISTINCT m.id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        name p ON a.person_id = p.imdb_id
    GROUP BY 
        a.id, a.name, t.id, t.title, t.production_year, c.kind, p.gender
),
filtered_movies AS (
    SELECT 
        *,
        COALESCE(company_kind, 'Independent') AS final_company
    FROM 
        movie_data
    WHERE 
        production_year >= 2000
        AND (gender IS NULL OR gender = 'M')
),
ranked_movies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY final_company ORDER BY production_year DESC) AS ranking
    FROM 
        filtered_movies
)
SELECT 
    aka_name, 
    title, 
    final_company, 
    production_year, 
    ranking
FROM 
    ranked_movies
WHERE 
    ranking <= 5
ORDER BY 
    final_company, 
    production_year DESC; 
