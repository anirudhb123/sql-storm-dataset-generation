WITH RecursiveCTE AS (
    SELECT 
        c1.person_id, 
        c1.movie_id,
        COUNT(*) AS role_count,
        SUM(CASE WHEN ak.name IS NOT NULL THEN 1 ELSE 0 END) AS aka_count
    FROM 
        cast_info AS c1
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c1.person_id
    GROUP BY 
        c1.person_id, c1.movie_id
), 
MovieRoleRanking AS (
    SELECT 
        c.person_id,
        c.movie_id,
        c.role_count,
        c.aka_count,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.role_count DESC) AS role_rank
    FROM 
        RecursiveCTE AS c
), 
CompanyMovieStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ARRAY_AGG(DISTINCT co.name) FILTER (WHERE co.country_code = 'USA') AS usa_companies
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    mr.person_id,
    mr.role_rank,
    mcs.company_count,
    mcs.usa_companies,
    (SELECT STRING_AGG(mk.keyword, ', ')  
     FROM movie_keyword AS mk 
     WHERE mk.movie_id = tt.id) AS keywords,
    COALESCE((SELECT pi.info FROM person_info AS pi 
              WHERE pi.person_id = mr.person_id 
              AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')), 'N/A') AS biography,
    CASE 
        WHEN mr.role_rank <= 3 THEN 'Lead Role'
        WHEN mr.role_rank IS NULL THEN 'Not in Cast'
        ELSE 'Supporting Role'
    END AS role_category
FROM 
    title AS tt
LEFT JOIN 
    MovieRoleRanking AS mr ON tt.id = mr.movie_id
LEFT JOIN 
    CompanyMovieStats AS mcs ON tt.id = mcs.movie_id
WHERE 
    tt.production_year BETWEEN 2000 AND 2023
    AND (mcs.company_count IS NULL OR mcs.company_count > 2)
    AND (mr.role_rank <= 5 OR mr.role_rank IS NULL)
ORDER BY 
    tt.production_year DESC, 
    mr.role_rank, 
    tt.title;
