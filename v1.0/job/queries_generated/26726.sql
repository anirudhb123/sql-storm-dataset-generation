WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
), 

title_keywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
), 

company_info AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
)

SELECT 
    rt.aka_name,
    rt.movie_title,
    rt.production_year,
    tk.keyword,
    ci.companies,
    ci.company_types
FROM 
    ranked_titles rt
JOIN 
    title_keywords tk ON rt.aka_id = tk.title_id
JOIN 
    company_info ci ON rt.aka_id = ci.movie_id
WHERE 
    rt.rank = 1 
    AND rt.production_year >= 2000 
    AND tk.keyword IS NOT NULL
ORDER BY 
    rt.production_year DESC, 
    rt.aka_name;

This query benchmarks string processing by:

1. Ranking titles per person in `aka_name` based on the production year.
2. Gathering keywords related to those titles.
3. Collecting information about the companies associated with the films.
4. Filtering for the most recent titles post-2000.
5. Aggregating results and ordering them to extract meaningful insights.
