WITH RankedTitles AS (
    SELECT
        a.name AS actor_name,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        a.name, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        rt.actor_name,
        rt.title,
        rt.production_year,
        rt.year_rank
    FROM 
        RankedTitles rt
    WHERE 
        rt.year_rank <= 5 AND rt.actor_name IS NOT NULL 
)
SELECT
    ft.actor_name,
    ft.title,
    ft.production_year,
    CASE 
        WHEN ft.title LIKE '%(uncredited)%' THEN 'Yes'
        ELSE 'No'
    END AS uncredited_role,
    COALESCE(o.note, 'No additional notes') AS movie_notes,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types
FROM
    FilteredTitles ft
LEFT JOIN
    movie_companies mc ON ft.production_year = mc.movie_id
LEFT JOIN
    company_type c ON mc.company_type_id = c.id
LEFT JOIN
    movie_info mi ON ft.production_year = mi.movie_id
LEFT JOIN
    (SELECT movie_id, STRING_AGG(note, '; ') AS note 
     FROM movie_info 
     GROUP BY movie_id
     HAVING COUNT(*) > 0) AS o ON ft.production_year = o.movie_id
GROUP BY
    ft.actor_name, ft.title, ft.production_year, o.note
HAVING
    COUNT(DISTINCT mc.company_id) > 0 OR ft.actor_name IS NULL
ORDER BY
    ft.production_year DESC, ft.actor_name;

This query does the following:
1. It uses a CTE (`RankedTitles`) to rank movies based on the number of distinct actors for each production year.
2. A second CTE (`FilteredTitles`) filters the results to only include the top 5 ranked titles per year.
3. The final selection pulls in actor names, titles, production years, checks if the title contains "(uncredited)", counts the number of associated production companies, and aggregates the company types as a comma-separated list.
4. It uses outer joins to collect optional notes and counts of production companies, handling potential null values with `COALESCE`.
5. Finally, the results are ordered by production year and actor name, with a specific filtering condition in the `HAVING` clause to ensure results meet certain criteria.
