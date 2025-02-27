WITH RecursiveRoleCount AS (
    SELECT 
        ci.person_id,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
PersonRoleDetails AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_name,
        rc.role_count,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY rc.role_count DESC) AS rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        RecursiveRoleCount rc ON ak.person_id = rc.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ak.name IS NOT NULL
)
SELECT 
    p.actor_name,
    p.role_name,
    COALESCE(rt.title, 'Unknown Title') AS title,
    rt.production_year,
    CASE
        WHEN rt.title IS NULL THEN 'No Title Found'
        ELSE 'Title Exists'
    END AS title_status,
    p.role_count
FROM 
    PersonRoleDetails p
LEFT JOIN 
    RankedTitles rt ON p.role_count > 2 AND rt.title_rank = 1
WHERE 
    p.rank <= 3
ORDER BY 
    p.role_count DESC, 
    title_status DESC, 
    p.actor_name ASC;

This query incorporates several advanced SQL constructs:

1. **CTEs**: Used for breaking down the problem into logical parts, including `RecursiveRoleCount` to count roles per person, `RankedTitles` to rank titles by production year, and `PersonRoleDetails` to associate actors with their roles and counts.
  
2. **Window Functions**: Employed ROW_NUMBER to rank titles and count roles.

3. **Left Joins**: Used to fetch titles even if the actor has not played a lead role in more than 2 movies.

4. **COALESCE**: Handles NULL cases for titles, allowing for cleaner output.

5. **Complicated predicates**: The WHERE clause incorporates complex logic, ensuring filtering based on specific conditions like role count and ranking.

6. **CASE Statement**: Provides a semantic check to establish the existence of a title.

7. **Ordering**: Ensures the results are sorted first by role count, then by title status, and lastly by actor names.

This query is designed to extract detailed and nuanced insights about actors, their roles, and associated titles, showcasing the potential complexity and richness of the data in the schema.
