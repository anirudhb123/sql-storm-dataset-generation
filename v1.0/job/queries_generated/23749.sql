WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS movie_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
), 
CastWithRoles AS (
    SELECT 
        c.movie_id, 
        COUNT(c.role_id) AS role_count, 
        MAX(r.role) AS main_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
), 
CompanyDetails AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.name IS NOT NULL) AS company_names
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
) 
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cr.role_count,
    cr.main_role,
    cd.company_count,
    cd.company_names,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = rm.movie_id) AS keyword_count,
    COALESCE((
        SELECT 
            STRING_AGG(k.keyword, ', ')
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            mk.movie_id = rm.movie_id
    ), 'No Keywords') AS keywords,
    (CASE 
        WHEN cd.company_count > 5 THEN 'Big Production'
        WHEN cd.company_count IS NULL THEN 'No Company Info'
        ELSE 'Small Production'
    END) AS production_size
FROM 
    RankedMovies rm
LEFT JOIN 
    CastWithRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    (rm.production_year >= 2000 OR rm.production_year IS NULL)
    AND (cr.role_count IS NULL OR cr.role_count > 2)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
