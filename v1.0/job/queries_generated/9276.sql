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
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    m.role,
    m.role_count,
    c.company_name,
    c.company_type,
    k.keywords
FROM 
    title t
JOIN 
    MovieRoles m ON t.id = m.movie_id
JOIN 
    CompanyMovieInfo c ON t.id = c.movie_id
JOIN 
    MovieKeywords k ON t.id = k.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, m.role_count DESC, t.title;
