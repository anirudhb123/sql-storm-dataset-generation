WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_cast_order
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        character_name cn ON c.person_id = cn.imdb_id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        aka_title a ON a.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    GROUP BY 
        t.id
    HAVING 
        COUNT(DISTINCT c.person_id) > 10
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name || ' (' || ct.kind || ')') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        GROUP_CONCAT(DISTINCT mi.info || ': ' || mi.note) AS movie_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.avg_cast_order,
    COALESCE(mc.companies, 'No Companies') AS production_companies,
    COALESCE(mi.movie_details, 'No Additional Info') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;
