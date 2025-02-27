WITH RecursiveActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_type,
        ti.title AS movie_title,
        ti.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ti.production_year DESC) AS role_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title ti ON ci.movie_id = ti.movie_id
    JOIN 
        comp_cast_type ct ON ci.role_id = ct.id
    WHERE 
        ak.name IS NOT NULL 
        AND ct.kind IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        ARRAY_AGG(mk.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
FilteredTitles AS (
    SELECT 
        ti.title,
        ti.production_year,
        ROW_NUMBER() OVER (ORDER BY ti.production_year DESC) AS title_rank,
        COALESCE(tk.keywords, ARRAY[]::text[]) AS keywords
    FROM 
        aka_title ti
    LEFT JOIN 
        TitleKeywords tk ON ti.id = tk.movie_id
    WHERE 
        ti.production_year > 1990
        AND (ti.kind_id IS NOT NULL OR 
             ti.title ILIKE '%sequel%' OR 
             EXISTS (
                SELECT 1 
                FROM movie_info mii 
                WHERE mii.movie_id = ti.id 
                  AND mii.info ILIKE '%remake%'
              )
        )
),
AggregateRoleStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_roles,
        SUM(CASE WHEN role_rank = 1 THEN 1 ELSE 0 END) AS lead_roles
    FROM 
        RecursiveActorRoles
    GROUP BY 
        actor_name
)
SELECT 
    fr.actor_name,
    fr.total_roles,
    fr.lead_roles,
    ft.title,
    ft.production_year,
    ft.keywords
FROM 
    AggregateRoleStats fr
JOIN 
    RecursiveActorRoles ra ON fr.actor_name = ra.actor_name
JOIN 
    FilteredTitles ft ON ra.movie_title = ft.title
WHERE 
    fr.total_roles > 5 
    AND (fr.lead_roles * 1.0 / fr.total_roles) > 0.3  -- 30% lead role threshold
ORDER BY 
    fr.total_roles DESC, 
    ft.production_year ASC
LIMIT 10;

This query does several intricate operations:

1. **Recursive Common Table Expression (CTE)**: The first CTE, `RecursiveActorRoles`, gathers the names of actors, their roles, the titles of movies, and production year, along with their rank based on production year.

2. **Aggregating Keywords**: The `TitleKeywords` CTE aggregates keywords associated with each title.

3. **Filtering Movies**: The `FilteredTitles` CTE filters the titles to only those produced after 1990, incorporating criteria such as titles that are sequels or remakes.

4. **Aggregating Role Statistics**: The `AggregateRoleStats` CTE calculates the total number of roles and how many of those roles were lead roles per actor.

5. **Final Selection**: The final selection retrieves actors with more than 5 roles and at least 30% of those being lead roles, along with the titles they acted in that meet the specified criteria, sorted appropriately.

This query employs complex joins, aggregates, and conditional logic while demonstrating diverse SQL capabilities.
