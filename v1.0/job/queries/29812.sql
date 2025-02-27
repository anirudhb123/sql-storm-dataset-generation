WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5 
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
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfoDetailed AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mk.keywords,
        mc.companies,
        m.actor_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON m.movie_id = mc.movie_id
)
SELECT 
    mid.movie_id,
    mid.title,
    mid.production_year,
    mid.actor_count,
    mid.keywords,
    mid.companies
FROM 
    MovieInfoDetailed mid
ORDER BY 
    mid.actor_count DESC, 
    mid.production_year ASC
LIMIT 10;