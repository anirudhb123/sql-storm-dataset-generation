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
CastWithRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.person_role_id = r.id
),
MoviesWithKeywords AS (
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
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mc.note, 'No Note') AS note
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    cwr.actor_name,
    cwr.role_name,
    cwr.total_cast,
    COALESCE(mwk.keywords, 'No Keywords') AS keywords,
    cd.company_name,
    cd.company_type,
    cd.note
FROM 
    RankedMovies rm
LEFT JOIN 
    CastWithRoles cwr ON rm.movie_id = cwr.movie_id
LEFT JOIN 
    MoviesWithKeywords mwk ON rm.movie_id = mwk.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    (cwr.role_name IS NOT NULL OR cd.company_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
