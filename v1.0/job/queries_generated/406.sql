WITH RankedMovies AS (
    SELECT 
        a.movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.person_id,
    ar.role,
    mk.keywords,
    cm.companies,
    CASE 
        WHEN rm.year_rank <= 5 THEN 'Top 5 Movies'
        ELSE 'Other Movies'
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    (ar.person_id IS NOT NULL AND ar.role IS NOT NULL)
    OR mk.keywords IS NOT NULL
    OR cm.companies IS NOT NULL
ORDER BY 
    rm.production_year DESC, ar.role_order;
