WITH RecursiveMovieCast AS (
    SELECT 
        ci.movie_id, 
        ci.person_id, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
),
MovieKeywordStats AS (
    SELECT 
        mt.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
CompanyParticipation AS (
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
    WHERE 
        c.country_code IS NOT NULL
),
TitleInfo AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COALESCE(mt.keyword_count, 0) AS keyword_count,
        COALESCE(cp.company_name, 'Unknown') AS production_company,
        COALESCE(cp.company_type, 'Independent') AS company_type
    FROM 
        aka_title at
    LEFT JOIN 
        MovieKeywordStats mt ON at.id = mt.movie_id
    LEFT JOIN 
        CompanyParticipation cp ON at.id = cp.movie_id
)
SELECT 
    ti.title, 
    ti.production_year, 
    ti.keyword_count,
    ti.production_company,
    ti.company_type,
    RANK() OVER (ORDER BY ti.keyword_count DESC) AS keyword_rank,
    (SELECT 
        STRING_AGG(name.name, ', ')
    FROM 
        aka_name name
    INNER JOIN 
        cast_info ci ON name.person_id = ci.person_id
    WHERE 
        ci.movie_id = ti.movie_id) AS cast_names,
    CASE 
        WHEN ti.production_year < 2000 THEN 'Classic'
        WHEN ti.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    TitleInfo ti
WHERE 
    ti.keyword_count > 0
ORDER BY 
    ti.keyword_count DESC, ti.production_year DESC
LIMIT 50;

This query uses several constructs such as Common Table Expressions (CTEs), window functions for ranking, correlated subqueries for casting names, and case statements to categorize movies by era. It performs outer joins to gather related data across multiple tables, effectively filtering and aggregating results while considering NULL values. The SQL also features an intricate structure designed to facilitate performance benchmarking through complex relationships.
