WITH RankedTitles AS (
    SELECT 
        a.person_id,
        a.name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
RecentTitles AS (
    SELECT *
    FROM RankedTitles
    WHERE rn <= 5
),
KeywordCounts AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline') 
        AND mk.keyword_id IS NOT NULL
    GROUP BY 
        mt.movie_id
),
CompanyContributions AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cp.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year AS year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COALESCE(cc.company_count, 0) AS company_count,
    COALESCE(cc.company_names, 'No Companies') AS company_names
FROM 
    RecentTitles rt
LEFT JOIN 
    KeywordCounts kc ON rt.movie_id = kc.movie_id
LEFT JOIN 
    CompanyContributions cc ON rt.movie_id = cc.movie_id
WHERE 
    (rt.production_year BETWEEN 2000 AND 2030 OR rt.title LIKE '%Epic%')
ORDER BY 
    rt.production_year DESC, rt.actor_name;

Explanation of constructs used:

1. **Common Table Expressions (CTEs)**: 
    - `RankedTitles`: Ranks titles for each actor based on the production year.
    - `RecentTitles`: Filters the top 5 recent titles for each actor.
    - `KeywordCounts`: Counts distinct keywords associated with movies' taglines.
    - `CompanyContributions`: Counts distinct companies associated with movies and aggregates their names.

2. **Window Function**: 
    - `ROW_NUMBER()` to assign rankings based on production year.

3. **Outer Joins**: 
    - LEFT JOIN to include movies that might not have associated keywords or company data.

4. **Complex Predicates**: 
    - Filters for production years and titles containing 'Epic'.
  
5. **COALESCE**: 
    - Used to substitute NULL values with defaults in the results.

6. **String Aggregation**:
    - `STRING_AGG` to concatenate all company names associated with a movie.

7. **NULL Logic**: 
    - Handling NULLs to ensure meaningful output when there are missing relationships.

This query demonstrates a thorough use of SQL constructs and aims to provide insights into the recent works of actors, the keywords associated, and the companies involved in movie production over a specific timeframe.
