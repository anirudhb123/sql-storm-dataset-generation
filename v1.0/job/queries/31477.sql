WITH RECURSIVE RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_within_year
    FROM 
        aka_title m
),
MovieCast AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        r.role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyMovies AS (
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
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
LatestMovies AS (
    SELECT 
        title, 
        COUNT(*) AS keyword_count,
        MAX(production_year) AS latest_year
    FROM 
        RankedMovies rm
    JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    GROUP BY 
        title
)
SELECT 
    rm.title, 
    rm.production_year, 
    mc.actor_name, 
    mc.role, 
    cm.company_name, 
    cm.company_type, 
    lm.keyword_count, 
    lm.latest_year
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    LatestMovies lm ON rm.title = lm.title
WHERE 
    rm.production_year = (
        SELECT MAX(production_year) 
        FROM aka_title
    )
ORDER BY 
    lm.keyword_count DESC, 
    rm.title;
