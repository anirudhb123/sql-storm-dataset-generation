WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        COALESCE(ki.keyword, 'No Keyword') AS keyword,
        COUNT(c.person_id) AS cast_count,
        SUM(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_filled,
        GREATEST(0, COUNT(c.role_id) - COUNT(DISTINCT c.person_role_id)) AS unfilled_roles
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year, ki.keyword
), 
ActiveDirectors AS (
    SELECT 
        p.id AS person_id,
        p.name AS director_name,
        md.movie_id,
        COUNT(DISTINCT md.company_id) AS companies_count
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        movie_companies md ON cc.movie_id = md.movie_id
    WHERE 
        ci.role_id IN (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        p.id, p.name, md.movie_id
),
AggregatedDirectorStats AS (
    SELECT 
        director_name,
        COUNT(DISTINCT movie_id) AS directed_movies,
        SUM(companies_count) AS total_companies
    FROM 
        ActiveDirectors
    GROUP BY 
        director_name
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    mv.keyword,
    mv.cast_count,
    mv.roles_filled,
    mv.unfilled_roles,
    ad.directed_movies,
    ad.total_companies,
    CASE 
        WHEN mv.unfilled_roles > 0 THEN 'Needs Attention' 
        ELSE 'Fully Cast'
    END AS cast_status,
    CONCAT(mv.title, ' - ', COALESCE(ad.director_name, 'Unknown Director')) AS detailed_title
FROM 
    RecursiveMovieCTE mv
LEFT JOIN 
    AggregatedDirectorStats ad ON mv.cast_count >= 3 AND ad.directed_movies > 0
WHERE 
    mv.year_rank <= 5 
    AND mv.keyword NOT LIKE '%Invalid%' 
    AND mv.production_year IS NOT NULL
ORDER BY 
    mv.production_year DESC, ad.total_companies DESC;

This query employs multiple advanced SQL constructs:

1. **Common Table Expressions (CTEs)**: Used for recursive movie statistics and aggregating director data.
2. **Window Functions**: Rank the movies within their production year.
3. **Outer Joins**: Joining tables while maintaining records even if some relationships may not exist.
4. **Complex Aggregations**: Counting roles filled and unfilled roles, providing insight into the casting process.
5. **Conditional Logic**: Using `CASE` to evaluate the casting situation.
6. **String Functions**: Formulating a detailed title as a single string.
7. **Complicated Predicates**: Filtering based on conditions across multiple join outcomes. 

This query showcases proficiency in SQL by incorporating a wide range of SQL constructs making it an interesting benchmark for performance testing under complex scenarios.
