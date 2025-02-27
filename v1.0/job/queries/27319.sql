
WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),

title_keywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
),

company_movies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
)

SELECT 
    rt.aka_name,
    rt.movie_title,
    rt.production_year,
    rt.rank_year,
    tk.keywords,
    cm.companies
FROM 
    ranked_titles rt
LEFT JOIN 
    title_keywords tk ON rt.aka_id = tk.title_id
LEFT JOIN 
    company_movies cm ON rt.aka_id = cm.movie_id
WHERE 
    rt.rank_year = 1
ORDER BY 
    rt.production_year DESC, rt.aka_name;
