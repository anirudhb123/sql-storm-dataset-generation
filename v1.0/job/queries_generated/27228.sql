WITH PopularMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
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
    pm.title,
    pm.production_year,
    pm.cast_count,
    mk.keywords,
    mc.companies,
    mc.company_types
FROM 
    PopularMovies pm
LEFT JOIN 
    MovieKeywords mk ON pm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON pm.movie_id = mc.movie_id
ORDER BY 
    pm.production_year DESC, 
    pm.cast_count DESC;
