WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
CombinedInfo AS (
    SELECT 
        n.name AS person_name,
        c.movie_id,
        t.title AS movie_title,
        r.role AS person_role,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        title t ON c.movie_id = t.id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ci.person_name,
    ci.movie_title,
    ci.person_role,
    rt.keyword,
    rt.title_rank
FROM 
    RankedTitles rt
LEFT JOIN 
    CombinedInfo ci ON ci.movie_title = rt.title
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title_rank;

This query performs a series of operations to benchmark string processing through the following steps:
1. **CTE (Common Table Expression) `RankedTitles`**: This CTE selects titles from the `aka_title` table along with their associated keywords, ranks the titles based on their length for each production year, and filters out any titles with a null `production_year`.
2. **CTE `CombinedInfo`**: This CTE retrieves the names of cast members, their associated movie titles, and roles by joining the necessary tables together.
3. **Final Selection**: The final `SELECT` statement combines the results from the two CTEs, pulling relevant fields and ordering the output by production year and title rank to facilitate a string processing benchmark by examining the lengths of titles and the number of cast members related to top titles per year. The results are filtered to show only the top 5 titles per production year based on title length.
