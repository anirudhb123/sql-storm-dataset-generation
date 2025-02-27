WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    JOIN 
        aka_title a ON t.id = a.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        r.role,
        COUNT(c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, r.role
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
),
CompanyDetail AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.title_id,
    m.title,
    m.production_year,
    m.imdb_index,
    a.person_id,
    a.role,
    a.movie_count,
    mk.keywords,
    cd.companies,
    cd.company_types
FROM 
    RankedMovies m
LEFT JOIN 
    ActorRoles a ON m.title_id = a.movie_count
LEFT JOIN 
    MovieKeywords mk ON m.title_id = mk.movie_id
LEFT JOIN 
    CompanyDetail cd ON m.title_id = cd.movie_id
WHERE 
    m.rn <= 5 -- Limiting to top 5 titles per year for brevity
ORDER BY 
    m.production_year DESC, 
    m.title;
