WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS movie_rank
    FROM 
        aka_title a
    JOIN 
        cast_info b ON a.id = b.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        k.keyword,
        mk.movie_id
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
Filmography AS (
    SELECT 
        p.id AS person_id,
        n.name AS person_name,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY p.id ORDER BY cf.movie_id) AS role_rank
    FROM 
        cast_info cf
    JOIN 
        aka_name n ON cf.person_id = n.person_id
    JOIN 
        role_type r ON cf.role_id = r.id
)
SELECT 
    m.title,
    m.production_year,
    fk.person_name,
    fk.role,
    mk.keyword,
    COALESCE(ci.company_name, 'Independent') AS company_name,
    ci.company_type,
    CASE 
        WHEN m.movie_rank = 1 THEN 'Best of the Year'
        ELSE 'Regular Release'
    END AS movie_status
FROM 
    RankedMovies m
LEFT JOIN 
    Filmography fk ON m.id = fk.movie_id AND fk.role_rank <= 3
LEFT JOIN 
    CompanyInfo ci ON m.id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON m.id = mk.movie_id
WHERE 
    m.production_year >= 2000
    AND (ci.company_type IS NULL OR ci.company_type <> 'Unknown')
ORDER BY 
    m.production_year DESC, 
    m.title;
