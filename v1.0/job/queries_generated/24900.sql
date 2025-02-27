WITH ranked_titles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
title_keywords AS (
    SELECT 
        t.id AS title_id,
        k.keyword,
        COUNT(DISTINCT mk.movie_id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, k.keyword
),
companies_for_movie AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
filtered_companies AS (
    SELECT 
        movie_id,
        STRING_AGG(company_name || ' (' || company_type || ')', ', ') AS companies
    FROM 
        companies_for_movie
    GROUP BY 
        movie_id
)
SELECT 
    rt.aka_id,
    rt.aka_name,
    rt.movie_title,
    rt.production_year,
    fk.keyword_count AS keyword_usage,
    fc.companies
FROM 
    ranked_titles rt
LEFT JOIN 
    title_keywords fk ON rt.aka_id = fk.title_id AND rank = 1
LEFT JOIN 
    filtered_companies fc ON rt.aka_id = fc.movie_id
WHERE 
    rt.production_year = (SELECT MAX(production_year) FROM ranked_titles WHERE aka_id = rt.aka_id)
    AND rt.aka_name IS NOT NULL
ORDER BY 
    rt.production_year DESC, rt.aka_name ASC
LIMIT 10;

This query incorporates several advanced SQL constructs, including:
- Common Table Expressions (CTEs) to structure complex calculations.
- Window functions (`ROW_NUMBER()`) to rank titles for each person.
- Joins across multiple tables to aggregate information about movies, keywords, and companies.
- String aggregation to concatenate company names and types.
- A correlated subquery to filter the most recent production year for each actor.
- Complicated SELECT statements to provide a comprehensive view of the data.
