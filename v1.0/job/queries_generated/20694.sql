WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithRoleCounts AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.id) AS role_count,
        AVG(COALESCE(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END, 1)) AS average_role_note 
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
),
MoviesWithCompanyInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(cn.name, 'Unknown') AS company_name,
        COUNT(mc.id) AS company_count
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.id, m.title, cn.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword_count,
    a.actor_name,
    a.role_count,
    mc.company_name,
    mc.company_count,
    CASE 
        WHEN rm.rank <= 3 THEN 'Top Movie'
        WHEN rm.rank BETWEEN 4 AND 10 THEN 'Mid Tier Movie'
        ELSE 'Low Tier Movie'
    END AS movie_tier,
    STRING_AGG(DISTINCT rk.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorsWithRoleCounts a ON rm.title_id IN (SELECT ci.movie_id FROM cast_info ci JOIN aka_name ak ON ak.person_id = ci.person_id WHERE ak.name = a.actor_name)
LEFT JOIN 
    MoviesWithCompanyInfo mc ON rm.title_id = mc.movie_id
LEFT JOIN 
    movie_keyword rk ON rm.title_id = rk.movie_id
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
GROUP BY 
    rm.title, rm.production_year, a.actor_name, a.role_count, mc.company_name, mc.company_count, rm.rank
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC;

This SQL query incorporates multiple advanced SQL constructs including Common Table Expressions (CTEs), window functions, outer joins, correlated subqueries, string aggregation, and NULL handling. It retrieves information about movies ranked by the number of keywords associated with them, along with actor roles and associated companies. Furthermore, it categorizes movies into tiers based on their rank while applying filters on the production year, showcasing a complex and carefully structured logic.
