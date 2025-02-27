WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank,
        SUM(CASE WHEN k.keyword = 'action' THEN 1 ELSE 0 END) OVER (PARTITION BY a.id) AS action_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        coalesce(ct.kind, 'Unknown') as role_type,
        DENSE_RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type ct ON ci.role_id = ct.id
),
CompanyAndInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    cm.company_count,
    cm.company_names,
    cwr.role_type,
    cwr.role_order,
    rm.action_count
FROM 
    RankedMovies rm
JOIN 
    CompanyAndInfo cm ON rm.id = cm.movie_id
LEFT JOIN 
    CastInfoWithRoles cwr ON rm.id = cwr.movie_id
WHERE 
    (cm.company_count > 0 OR rm.year_rank = 1) -- Even if no companies, show top productions 
    AND (cwr.role_order IS NULL OR cwr.role_order <= 5) -- Show only main cast roles
ORDER BY 
    m.production_year DESC, 
    rm.action_count DESC, 
    cwr.role_order ASC
;

In this query:

- **Common Table Expressions (CTEs)** are utilized to structure the query into manageable parts. 
- `RankedMovies` CTE ranks movies by their production year, counting the number of 'action' keywords for each movie.
- `CastInfoWithRoles` CTE gathers actor roles, assigning a dense ranking to maintain order based on their appearance in the movie list.
- `CompanyAndInfo` CTE computes a count and concatenated list of companies associated with each movie.
- The final SELECT statement joins this data together, applying various predicates to filter the result set, including checks for presence of companies and a limit on the roles displayed for cast members.
- The use of `COALESCE` ensures we handle potential NULL values gracefully, while ranking and aggregation help in understanding the top movies in terms of production year and action-oriented themes.
