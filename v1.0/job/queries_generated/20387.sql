WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year, 
        COUNT(DISTINCT ca.person_id) AS actor_count,
        AVG(CASE WHEN ca.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS yearly_rank
    FROM 
        aka_title AS a
    JOIN 
        cast_info AS ca ON a.id = ca.movie_id
    GROUP BY 
        a.title, a.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        MAX(CASE WHEN cn.country_code IS NULL THEN 1 ELSE 0 END) AS has_null_country
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        cs.company_count,
        cs.company_names,
        rm.actor_count,
        rm.has_note_ratio,
        rm.yearly_rank
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        CompanyStats AS cs ON rm.title = cs.movie_id
    WHERE 
        rm.actor_count > 0 AND 
        (rm.has_note_ratio < 0.5 OR cs.company_count IS NULL)
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.company_count, 0) AS total_companies,
    ARRAY_AGG(cs.name) FILTER (WHERE cs.name IS NOT NULL) AS associated_companies,
    fm.actor_count,
    RANK() OVER (ORDER BY fm.production_year DESC, fm.actor_count DESC) AS rank_within_year
FROM 
    FilteredMovies AS fm
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = fm.title LIMIT 1)
LEFT JOIN 
    company_name AS cs ON mc.company_id = cs.id
GROUP BY 
    fm.title, fm.production_year, fm.company_count, fm.actor_count
HAVING 
    MAX(fm.has_null_country) = 1 OR 
    COUNT(cs.id) > 10
ORDER BY 
    fm.production_year DESC, total_companies DESC;

In this query, we:

1. Use a Common Table Expression (CTE) to rank movies based on their number of actors while calculating the ratio of actors with notes.
2. Create another CTE to aggregate company information related to the movies.
3. Filter out movies based on conditions like the number of actors and the presence of companies.
4. Utilize outer joins and window functions to generate a final selection with ranks and company details.
5. Implement complex predicates using NULL logic and conditional aggregations.
6. Apply STRING_AGG for concatenating associated company names.
7. Make a nuanced use of HAVING clauses to filter based on conditional aggregates. 

This illustrates advanced SQL features while also highlighting strange corner cases and intricate conditions.
