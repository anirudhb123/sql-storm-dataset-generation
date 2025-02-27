WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonRoles AS (
    SELECT 
        ak.name AS actor_name,
        ct.kind AS role_type,
        m.title,
        m.production_year
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON ak.person_id = c.person_id
    INNER JOIN 
        title m ON c.movie_id = m.id
    LEFT JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
),
MovieCompanyInfo AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) OVER (PARTITION BY m.id) AS total_companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    pm.actor_name,
    pm.role_type,
    mm.title,
    mm.production_year,
    COALESCE(mc.company_name, 'No Company') AS company_name,
    mm.total_cast,
    CASE 
        WHEN mm.total_cast > 10 THEN 'Blockbuster'
        WHEN mm.total_cast BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Independent' 
    END AS movie_scale
FROM 
    PersonRoles pm
JOIN 
    RankedMovies mm ON pm.title = mm.title AND pm.production_year = mm.production_year
LEFT JOIN 
    MovieCompanyInfo mc ON mm.title = mc.title
WHERE 
    pm.role_type IS NOT NULL
    AND mm.rank <= 5
    AND mm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    mm.production_year DESC, mm.total_cast DESC;

This SQL query performs the following:

1. **Common Table Expressions (CTEs)**: 
    - `RankedMovies`: This CTE ranks movies within the same production year based on the total number of cast members.
    - `PersonRoles`: This collects necessary information about actors, their roles, and the movies they have appeared in.
    - `MovieCompanyInfo`: This collects information about the companies associated with movies.

2. **JOINs & Conditions**: 
    - It utilizes various types of JOINs to extract and correlate relevant data from the different tables. 
    - It filters results to only include roles that are not NULL and limits to the top-ranked movies produced between 2000 and 2020.

3. **CASE Statements**: 
    - It categorizes movies based on the total cast into 'Blockbuster', 'Moderate', or 'Independent'.

4. **Using COALESCE**: 
    - Coalesces the company name to "No Company" if there is no associated company.

5. **Window Functions**: 
    - Applies a window function to count the number of companies linked to each movie, which allows complex aggregations while preserving row-level details.

The query provides a rich view of actors, their roles, and the associated movie details, which can be useful for performance benchmarking scenarios.
