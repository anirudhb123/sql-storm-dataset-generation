WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS total_cast,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS movie_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
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
        STRING_AGG(co.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        SUM(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS total_roles
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    mk.keywords,
    mc.companies,
    cd.actors,
    cd.total_roles,
    CASE 
        WHEN rm.movie_rank = 1 THEN 'Top Movie of ' || rm.production_year 
        ELSE 'Rank #' || rm.movie_rank 
    END AS rank_description
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.total_cast > 10 OR (rm.production_year IS NOT NULL AND mk.keywords IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;

-- Ensure that we are handling NULL values appropriately, so that if there are no keywords or companies, we still show the movie
