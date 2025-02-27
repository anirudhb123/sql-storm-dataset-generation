WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id DESC) AS rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
PersonRoles AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        rp.role AS role_name,
        COUNT(ca.id) AS role_count
    FROM 
        cast_info ca
    JOIN 
        role_type rp ON ca.role_id = rp.id
    GROUP BY 
        ca.person_id, ca.movie_id, rp.role
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    pr.role_name,
    pr.role_count,
    COALESCE(mc.company_name, 'Independent') AS production_company,
    COUNT(DISTINCT km.keyword) AS keyword_count,
    STRING_AGG(DISTINCT km.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    PersonRoles pr ON rm.movie_id = pr.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword km ON mk.keyword_id = km.id
WHERE 
    (rm.production_year > 1990 OR rm.production_year IS NULL) 
    AND (pr.role_name LIKE '%Director%' OR pr.role_name IS NULL)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, pr.role_name, mc.company_name
HAVING 
    COUNT(DISTINCT pr.person_id) > 1
ORDER BY 
    rm.production_year DESC,
    keyword_count DESC NULLS LAST;

### Explanation:
- **Common Table Expressions (CTEs)**: 
  - `RankedMovies` ranks movies by production year.
  - `PersonRoles` counts the number of roles per person per movie.
  - `MovieCompanies` joins movie companies with their types for a consolidated view.

- **Main Query**: 
  - Selects relevant movie details, roles, production companies, and counts keywords associated with each movie.
  - Includes outer joins to ensure we still include movies without roles or companies.

- **WHERE Clause**: 
  - Filters for movies made after 1990 (or NULL) and roles that match a specific pattern (e.g., '%Director%').

- **HAVING Clause**: 
  - Ensures movies have more than one distinct person associated with roles.

- **NULL Logic**: 
  - Uses the `COALESCE` function to default to 'Independent' for movies with no associated production company.

- **String Aggregation**: 
  - Collects all distinct keywords related to each movie into a single string for better presentation.

- **Ordering**: 
  - Orders first by production year in descending order, then by keyword count, placing movies with NULL keyword counts last. 

This SQL query represents a complex interaction of multiple tables, joins, rankings, and aggregations, showcasing intricate SQL semantics.
