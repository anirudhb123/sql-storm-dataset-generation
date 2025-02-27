WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        m.production_year DESC
    LIMIT 10
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT CASE WHEN it.info = 'Summary' THEN mi.info END, '; ') AS summary,
        STRING_AGG(DISTINCT CASE WHEN it.info = 'Ratings' THEN mi.info END, '; ') AS ratings
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actors,
    mc.company_count,
    mc.companies,
    mi.summary,
    mi.ratings
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
