WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(annual_salary) AS avg_salary,
        DENSE_RANK() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    LEFT JOIN (
        SELECT 
            ci.movie_id,
            p.person_id,
            p.salary AS annual_salary
        FROM 
            cast_info ci
        JOIN 
            person_info p ON ci.person_id = p.person_id
        WHERE 
            p.info_type_id = (SELECT id FROM info_type WHERE info = 'Annual Salary')
    ) p ON m.id = p.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id
),
HighlightedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.avg_salary,
        cm.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.avg_salary DESC) AS avg_salary_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type cm ON mc.company_type_id = cm.id
),
FilteredMovies AS (
    SELECT 
        hm.*
    FROM 
        HighlightedMovies hm
    WHERE 
        hm.actor_count > 5 OR
        (hm.avg_salary_rank <= 3 AND hm.company_type IS NOT NULL)
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    COALESCE(fm.avg_salary, 0) AS avg_salary,
    string_agg(DISTINCT cn.name, ', ') AS companies
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    fm.production_year BETWEEN 2000 AND 2020
GROUP BY 
    fm.movie_id
HAVING 
    COUNT(DISTINCT cn.id) > 2
ORDER BY 
    fm.production_year DESC,
    avg_salary DESC;

This SQL query includes complex constructs such as CTEs (Common Table Expressions), window functions like `DENSE_RANK()` and `ROW_NUMBER()`, an outer joins for movies with company details, filtering with predicates that include both `OR` logic and `NULL` checks, and aggregates for collecting associated company names. The query also contains aggregate functions, calculates average salaries based on subjoined data, and filters based on unique conditions for production years and actor counts, showcasing intricate SQL semantics and query structure.
