WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
Ranking AS (
    SELECT 
        mt.movie_id,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ca ON mt.movie_id = ca.movie_id
    GROUP BY 
        mt.movie_id, mt.production_year
    HAVING 
        COUNT(DISTINCT ca.person_id) > 0
)
SELECT 
    mt.title,
    mt.production_year,
    mv.role_count,
    mk.keywords_list,
    mc.companies,
    r.rank
FROM 
    aka_title mt
LEFT JOIN 
    MovieRoles mv ON mt.movie_id = mv.movie_id
LEFT JOIN 
    MovieKeywords mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON mt.movie_id = mc.movie_id
JOIN 
    Ranking r ON mt.movie_id = r.movie_id
WHERE 
    mt.production_year >= 2000 AND (mv.role_count > 1 OR mk.keywords_list IS NOT NULL)
ORDER BY 
    r.rank, mt.production_year DESC;
