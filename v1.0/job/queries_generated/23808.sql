WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TitleCompanyCount AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        cc.actor_count,
        cd.companies_involved,
        CASE 
            WHEN cc.actor_count IS NULL THEN 'No Cast'
            WHEN cc.actor_count < 3 THEN 'Low Casting'
            ELSE 'Well Cast'
        END AS casting_quality
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CastCounts cc ON rt.title_id = cc.movie_id
    LEFT JOIN 
        CompanyDetails cd ON rt.title_id = cd.movie_id
)
SELECT 
    title,
    production_year,
    actor_count,
    companies_involved,
    casting_quality
FROM 
    TitleCompanyCount
WHERE 
    casting_quality = 'Well Cast'
    OR (actor_count IS NULL AND production_year < 1980)
ORDER BY 
    production_year DESC, 
    title;

### Explanation:
- **CTEs (Common Table Expressions)**:
  - `RankedTitles`: Ranks titles within their production year.
  - `CastCounts`: Counts distinct actors per movie.
  - `CompanyDetails`: Aggregates the names of companies involved in each movie.

- **Main Select** combines:
  - The title, year, actor count, and companies involved with a derived `casting_quality`.
  
- The WHERE clause filters for well-cast movies or titles with no cast before 1980.

- The ORDER BY clause sorts results by production year (descending) and then by title.

This query demonstrates a mix of advanced SQL constructs, aggregate functions, string aggregations, CASE logic, and filters, providing a comprehensive view of movie titles based on their production year and casting quality.
