WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.person_id,
        c.movie_id,
        ci.kind AS role_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        comp_cast_type ci ON c.role_id = ci.id
),
CompanyAggregates AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    ca.company_count,
    ca.company_names,
    cd.role_name,
    COALESCE(cd.role_rank, 'N/A') AS role_rank,
    CASE 
        WHEN ca.company_count > 5 THEN 'Many Companies'
        WHEN ca.company_count IS NULL THEN 'No Companies'
        ELSE 'Few Companies'
    END AS company_status
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    RankedTitles rt ON c.movie_id = rt.title_id AND rt.rn = 1
JOIN 
    CompanyAggregates ca ON rt.title_id = ca.movie_id
LEFT JOIN 
    CastDetails cd ON c.movie_id = cd.movie_id AND c.person_id = cd.person_id
WHERE 
    a.name IS NOT NULL
    AND a.name NOT LIKE '%test%'
ORDER BY 
    t.production_year DESC, a.name;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `RankedTitles`: Ranks titles for each production year and filters out titles without production years.
   - `CastDetails`: Retrieves cast information along with a rank based on the order of appearance in each movie.
   - `CompanyAggregates`: Aggregates company information linked to each movie, counting and concatenating names.

2. **Main Query**:
   - Joins the actor names, cast info, ranked titles, and aggregated company information.
   - Uses `COALESCE` to handle NULL case scenarios in ranks. 
   - Applies a `CASE` statement to provide a descriptive status based on the number of companies involved with each movie.
   - Filters out actors whose names contain 'test'.
   - The results are ordered by production year in descending order and actor name.

This query highlights the use of multiple advanced SQL features to create a rich dataset for performance benchmarking while also including intricate logical handling of NULL values and business logic expressions.
