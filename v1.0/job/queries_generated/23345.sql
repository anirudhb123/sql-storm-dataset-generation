WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
company_roles AS (
    SELECT 
        cc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        r.role AS role_name,
        COUNT(c.id) AS num_roles
    FROM 
        movie_companies cc
    JOIN 
        company_name c ON cc.company_id = c.id
    JOIN 
        company_type ct ON cc.company_type_id = ct.id
    JOIN 
        complete_cast cc2 ON cc.movie_id = cc2.movie_id
    JOIN 
        role_type r ON cc2.role_id = r.id
    GROUP BY 
        cc.movie_id, c.name, ct.kind, r.role
),
actor_info AS (
    SELECT 
        a.id AS person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS co_actors
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        a.id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
)
SELECT 
    tt.title,
    tt.production_year,
    tt.title_rank,
    tt.total_titles,
    cr.company_name,
    cr.company_type,
    ai.actor_name,
    ai.movie_count,
    ai.co_actors
FROM 
    ranked_titles tt
LEFT JOIN 
    movie_companies mc ON tt.title_id = mc.movie_id
LEFT JOIN 
    company_roles cr ON tt.title_id = cr.movie_id
LEFT JOIN 
    cast_info ci ON tt.title_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    actor_info ai ON ak.person_id = ai.person_id
WHERE 
    (tt.production_year < 2000 OR tt.production_year IS NULL)
    AND (cr.company_type IS NOT NULL OR cr.company_name IS NOT NULL)
ORDER BY 
    tt.production_year DESC, tt.title_rank ASC
LIMIT 100;

### Explanation:
- **Common Table Expressions (CTEs)**: The query utilizes two CTEs (`ranked_titles` and `company_roles`) to compute rank and aggregate company roles, respectively.
- **Window Functions**: `ROW_NUMBER()` and `COUNT()` window functions are used to structure `ranked_titles`.
- **Set Operators**: If you wanted to extend the query to include more complex unions or intersections, you could add further layers with set operators.
- **String Aggregation**: `STRING_AGG` is used to gather co-actor names into a single string.
- **Filter Aggregation**: The `FILTER` clause within aggregation allows for conditional aggregation.
- **Outer Joins and Complicated `WHERE` Logic**: Incorporation of `LEFT JOINs` with predicates on potential `NULL` values to handle unconventional logic.
- **Predicates & Sorting**: The query filters productions before 2000 and sorts results; it also aggregates counts and string lists dynamically while avoiding duplicate entries.
