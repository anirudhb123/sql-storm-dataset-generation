WITH MovieKeywordCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
AkaNameDetails AS (
    SELECT 
        an.person_id,
        STRING_AGG(DISTINCT an.name, ', ') AS aka_names
    FROM 
        aka_name an
    GROUP BY 
        an.person_id
),
RoleStatistics AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.person_role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    mkc.keyword_count,
    a.aka_names,
    rs.role,
    rs.role_count,
    cmc.company_count
FROM 
    title t
LEFT JOIN 
    MovieKeywordCounts mkc ON t.id = mkc.movie_id
LEFT JOIN 
    AkaNameDetails a ON a.person_id IN (
        SELECT person_id FROM cast_info ci WHERE ci.movie_id = t.id
    )
LEFT JOIN 
    RoleStatistics rs ON rs.movie_id = t.id
LEFT JOIN 
    CompanyMovieCount cmc ON cmc.movie_id = t.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    mkc.keyword_count DESC, 
    cmc.company_count DESC;
