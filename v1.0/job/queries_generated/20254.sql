WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT ki.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        MAX(r.role) AS main_role
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cc.name) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.keyword_count,
    cd.cast_count,
    cd.main_role,
    co.company_count,
    co.company_names
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    CompanyDetails co ON rt.title_id = co.movie_id
WHERE 
    (rt.production_year IS NOT NULL AND rt.keyword_count >= 2 AND co.company_count > 1) 
    OR (cd.cast_count IS NULL AND co.company_count IS NULL)
ORDER BY 
    rt.production_year DESC, rt.title_rank
LIMIT 100;

### Explanation:
- **Common Table Expressions (CTEs)** are used to create modular parts of the query:
    - **RankedTitles:** Retrieves titles and ranks them by production year and title while counting distinct keywords associated with each title.
    - **CastDetails:** Aggregates information about the cast of each movie, counting distinct actors and identifying the main role.
    - **CompanyDetails:** Calculates the number of companies involved in each movie and collects their names as a comma-separated string.
  
- The **final selection** combines these CTEs, filtering the output based on a complex logical condition which checks production year, keyword count, and company involvement:

    - Includes movies with at least two keywords and more than one company, or movies with NULL in cast and company counts.
  
- The query uses various SQL constructs including:
    - **LEFT JOIN**s for preserving all rows from the title regardless of matches on casts or companies.
    - **ROW_NUMBER** window function to rank titles within their production years.
    - **STRING_AGG** function to concatenate names of companies.
  
- **Sorting** by production year in descending order and title rank ensures the output is well-organized and limited to a manageable number of results.
