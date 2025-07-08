
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank 
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id, 
        r.role, 
        COUNT(*) AS num_roles 
    FROM 
        cast_info c 
    JOIN 
        role_type r ON c.role_id = r.id 
    GROUP BY 
        c.movie_id, r.role 
),
CompanyData AS (
    SELECT 
        m.movie_id, 
        co.name AS company_name, 
        ct.kind AS company_type 
    FROM 
        movie_companies m 
    JOIN 
        company_name co ON m.company_id = co.id 
    JOIN 
        company_type ct ON m.company_type_id = ct.id 
),
MovieKeyword AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id 
)

SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    cr.role, 
    cr.num_roles, 
    cd.company_name, 
    cd.company_type, 
    mk.keywords 
FROM 
    RankedMovies rm 
LEFT JOIN 
    CastRoles cr ON rm.movie_id = cr.movie_id 
LEFT JOIN 
    CompanyData cd ON rm.movie_id = cd.movie_id 
LEFT JOIN 
    MovieKeyword mk ON rm.movie_id = mk.movie_id 
WHERE 
    rm.title_rank <= 5 
ORDER BY 
    rm.production_year DESC, 
    cr.num_roles DESC NULLS LAST;
