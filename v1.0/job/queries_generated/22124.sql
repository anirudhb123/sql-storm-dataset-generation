WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 1980 AND 2023
),
CompanyMovieCounts AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 5
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, rt.role
    HAVING 
        COUNT(*) > 3
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
OuterJoinMovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(mkc.movie_count, 0) AS movie_count,
        mk.keywords
    FROM 
        RankedTitles t
    LEFT JOIN 
        CompanyMovieCounts mkc ON mkc.movie_count > 5
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = t.title_id
)
SELECT 
    om.title,
    om.production_year,
    om.movie_count,
    om.keywords,
    CASE 
        WHEN om.movie_count = 0 THEN 'No Company'
        WHEN om.keywords IS NULL THEN 'No Keywords'
        ELSE 'Keyword Available'
    END AS keyword_status,
    COUNT(pc.info_type_id) AS person_info_count
FROM 
    OuterJoinMovieDetails om
LEFT JOIN 
    movie_info mi ON mi.movie_id IN (SELECT movie_id FROM movie_companies mc WHERE mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA'))
LEFT JOIN 
    person_info pc ON pc.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = om.title_id)
WHERE 
    om.production_year < 2020
GROUP BY 
    om.title, om.production_year, om.movie_count, om.keywords
ORDER BY 
    om.production_year DESC, om.title;

This query combines various SQL constructs:
- It uses Common Table Expressions (CTEs) to structure the data retrieval.
- It employs window functions for ranking titles by year.
- It has outer joins to include titles, companies, and keywords, while providing default values using `COALESCE`.
- There are correlated subqueries used in filters and joins to maintain contextual relevance.
- Complex logic with `CASE` statements to provide meaningful interpretations of results.
- Aggregate functions and GROUP BY to summarise data effectively.
- It's all framed around performance benchmarking for movies produced in the specified period, linking them with keyword data and company involvement.
