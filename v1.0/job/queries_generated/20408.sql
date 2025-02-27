WITH RecursiveMovieIDs AS (
    -- Recursive CTE to explore movies linked to each other
    SELECT m.movie_id
    FROM movie_link ml
    JOIN aka_title m ON ml.movie_id = m.movie_id
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT ml.linked_movie_id
    FROM movie_link ml
    JOIN RecursiveMovieIDs r ON ml.movie_id = r.movie_id
),
MovieKeywords AS (
    -- CTE capturing keywords for selected movies
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE mk.movie_id IN (SELECT movie_id FROM RecursiveMovieIDs)
    GROUP BY mk.movie_id
),
PersonRoles AS (
    -- CTE capturing distinct person roles per movie
    SELECT ci.movie_id, ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
),
MovieCompanies AS (
    -- CTE joining movie companies, filtering out certain company types with NULL checks
    SELECT mc.movie_id, c.name AS company_name, ct.kind AS type, rc.id AS company_id
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN RecursiveMovieIDs rc ON mc.movie_id = rc.movie_id
    WHERE ct.kind IS NOT NULL OR c.name IS NULL
)
-- Final query bringing everything together with outer joins and aggregate functions
SELECT 
    at.title,
    at.production_year,
    mk.keywords,
    pr.roles,
    string_agg(DISTINCT mc.company_name, ', ') AS companies
FROM aka_title at
LEFT JOIN MovieKeywords mk ON at.id = mk.movie_id
LEFT JOIN PersonRoles pr ON at.id = pr.movie_id
LEFT JOIN MovieCompanies mc ON at.id = mc.movie_id
WHERE 
    at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    AND (at.production_year IS NOT NULL OR at.production_year < 2020) -- Edge case on year filter
GROUP BY 
    at.title, at.production_year, mk.keywords, pr.roles
ORDER BY 
    at.production_year DESC, at.title
LIMIT 50;
