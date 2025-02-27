WITH Recursive_Cast AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rn
    FROM cast_info ci
    WHERE ci.movie_id IS NOT NULL
), 
Top_Movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT r.person_id) AS cast_count
    FROM aka_title t
    LEFT JOIN Recursive_Cast r ON t.id = r.movie_id
    GROUP BY t.id
    HAVING COUNT(DISTINCT r.person_id) > 5
), 
Average_Year AS (
    SELECT 
        AVG(CAST(production_year AS FLOAT)) AS avg_year
    FROM aka_title 
    WHERE production_year IS NOT NULL
),
Company_Count AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
), 
Cast_With_Roles AS (
    SELECT 
        r.person_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY r.person_id, rt.role
    HAVING COUNT(ci.id) > 1
)
SELECT 
    t.title,
    t.production_year,
    c.company_count,
    COALESCE(rc.rn, 0) AS role_rank,
    AVG(avg_year.avg_year) OVER () AS overall_avg_year,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    CASE 
        WHEN c.company_count >= 3 THEN 'Multi-Company'
        ELSE 'Single or No Company'
    END AS company_type
FROM Top_Movies t
LEFT JOIN Company_Count c ON t.movie_id = c.movie_id
LEFT JOIN Recursive_Cast rc ON t.movie_id = rc.movie_id
LEFT JOIN movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN Average_Year avg_year ON TRUE
GROUP BY t.movie_id, c.company_count, rc.rn
ORDER BY t.production_year DESC, company_names ASC
LIMIT 20
OFFSET (SELECT COUNT(*) FROM Top_Movies) / 2
;

This intricate SQL query achieves several goals:

- It uses Common Table Expressions (CTEs) to organize the intermediate results, including recursive queries.
- Various joins, including outer joins, are employed to gather data from multiple tables.
- The query includes window functions to calculate overall averages while still returning detailed records.
- The `STRING_AGG` function creates a list of company names associated with each movie.
- The `CASE` statement determines the classification of movies based on the number of associated companies.
- It manages NULL values with careful usage of COALESCE, ensuring that results remain accurate.
- The OFFSET clause, with a midpoint limit, adds complexity to the pagination aspect of the query while navigating through results. 

Overall, the query is designed to push performance boundaries while showcasing SQL's extensive, sometimes obscure functionalities.
