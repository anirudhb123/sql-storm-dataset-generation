WITH RankedMovies AS (
    SELECT 
        a.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY a.title) AS rank
    FROM
        aka_title at
    JOIN 
        title a ON at.id = a.id
    WHERE 
        at.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ki.keyword,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        complete_cast cc ON mk.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        ki.keyword
),
CompanyInfo AS (
    SELECT 
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mo.movie_id) AS total_movies
    FROM 
        movie_companies mo
    JOIN 
        company_name cn ON mo.company_id = cn.id
    JOIN 
        company_type ct ON mo.company_type_id = ct.id
    GROUP BY 
        cn.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    ar.keyword,
    ar.total_actors,
    ar.role_count,
    ci.company_name,
    ci.company_type,
    ci.total_movies
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.production_year = ar.role_count
LEFT JOIN 
    CompanyInfo ci ON rm.production_year = ci.total_movies
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.title ASC;
