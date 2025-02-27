WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m_comp.count DESC) AS movie_rank,
        COALESCE(m_comp.count, 0) AS company_count
    FROM 
        title t
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(company_id) AS count
        FROM 
            movie_companies
        GROUP BY 
            movie_id
    ) m_comp ON t.id = m_comp.movie_id
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.name,
        r.role,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name a
    INNER JOIN cast_info ci ON a.person_id = ci.person_id
    INNER JOIN role_type r ON ci.role_id = r.id
    WHERE 
        a.name IS NOT NULL 
        AND a.name <> ''
    GROUP BY 
        a.person_id, a.name, r.role
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.movie_id) AS movie_count
    FROM 
        company_name mn
    JOIN 
        movie_companies mc ON mn.id = mc.company_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mn.name, ct.kind
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COALESCE(ar.name, 'Unknown Actor') AS actor_name,
    COALESCE(ar.role, 'No Role') AS actor_role,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
    COALESCE(ci.company_name, 'Independent') AS production_company,
    rm.company_count,
    SUM(ci.movie_count) AS total_movies_by_company
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ar.person_id)
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id AND mk.keyword_rank = 1
LEFT JOIN 
    CompanyInfo ci ON ci.movie_count = rm.company_count
WHERE 
    (rm.movie_rank <= 5 OR ar.movie_count >= 3)
    AND (rm.production_year IS NOT NULL OR mk.keyword IS NOT NULL)
GROUP BY 
    rm.title, rm.production_year, ar.name, ar.role, mk.keyword, ci.company_name, rm.company_count
ORDER BY 
    rm.production_year DESC, movie_title
LIMIT 50;
