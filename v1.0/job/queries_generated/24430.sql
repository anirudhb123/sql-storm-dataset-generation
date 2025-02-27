WITH RecursiveRatings AS (
    SELECT 
        ti.id AS title_id,
        ti.title,
        ti.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY ti.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS yearly_rank
    FROM 
        aka_title ti
    LEFT JOIN 
        cast_info ci ON ci.movie_id = ti.movie_id
    WHERE 
        ti.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
    GROUP BY 
        ti.id, ti.title, ti.production_year
),
CompanyContributions AS (
    SELECT 
        mc.movie_id,
        COALESCE(SUM(CASE WHEN ct.kind LIKE 'Production%' THEN 1 ELSE 0 END), 0) AS production_company_count,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        mc.movie_id IN (SELECT movie_id FROM complete_cast)
    GROUP BY 
        mc.movie_id
),
RankedMovies AS (
    SELECT 
        rr.title_id,
        rr.title,
        rr.production_year,
        rr.cast_count,
        cc.production_company_count,
        cc.total_companies,
        rr.yearly_rank
    FROM 
        RecursiveRatings rr
    LEFT JOIN 
        CompanyContributions cc ON rr.title_id = cc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.production_company_count,
    rm.total_companies,
    CASE 
        WHEN rm.yearly_rank IS NULL THEN 'Unranked'
        WHEN rm.yearly_rank > 10 THEN 'Not Notable'
        ELSE 'Noteworthy'
    END AS rank_description
FROM 
    RankedMovies rm
WHERE 
    rm.production_year IS NOT NULL
  AND 
    rm.cast_count > (
        SELECT 
            AVG(cast_count) 
        FROM 
            RecursiveRatings 
        WHERE 
            production_year = rm.production_year
    )
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;

In this SQL query, we explore the relationships among multiple tables that form the Join Order Benchmark schema. The objective is to analyze the movies based on their cast sizes and the contributions of production companies.

1. **RecursiveRatings CTE**: This Common Table Expression (CTE) calculates the number of distinct cast members for each movie while also ranking them by the number of cast members in their respective production years.

2. **CompanyContributions CTE**: This CTE calculates the number of production companies involved in the movies and uses conditional aggregation to differentiate between types of companies (like "Production").

3. **RankedMovies CTE**: Here, we join the results from both previous CTEs and prepare the final dataset on which we can apply filtering and ranking logic.

4. **Final Select Statement**: The query retrieves the title, production year, cast count, number of production companies, and defines rank descriptions based on the yearly ranking. A subquery is utilized to filter out movies that exceed the average cast count for that particular production year.

This query includes several advanced SQL concepts: CTEs, joins, subqueries, window functions, and conditional logic while providing a robust benchmark for performance testing.
