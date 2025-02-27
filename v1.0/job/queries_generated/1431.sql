WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY tm.title ASC) AS title_rank
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
), 
CastDetails AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(CONCAT(a.name, ' (', rt.role, ')') ORDER BY c.nr_order) AS cast_list,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
), 
MovieInfo AS (
    SELECT 
        m.movie_id,
        MAX(m.info) AS longest_info
    FROM 
        movie_info m
    GROUP BY 
        m.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.cast_list,
    cd.total_cast,
    mi.longest_info,
    mci.total_companies,
    mci.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
WHERE 
    (rm.production_year IS NOT NULL AND rm.title_rank <= 10) 
    OR (cd.total_cast > 5 AND mci.total_companies IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.title ASC;
