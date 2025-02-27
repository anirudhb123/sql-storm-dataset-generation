WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
),
MovieCast AS (
    SELECT 
        c.movie_id,
        p.person_id,
        COALESCE(a.name, 'Unknown') AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id, 
        array_agg(DISTINCT mi.info) AS movie_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
),
Companies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.country_code IS NOT NULL
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    mca.actor_name,
    mca.role_name,
    mca.role_rank,
    co.company_name,
    co.company_type,
    mi.movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mca ON rm.movie_id = mca.movie_id
LEFT JOIN 
    Companies co ON rm.movie_id = co.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.production_year > 2000
    AND (mca.role_name IS NULL OR mca.role_name LIKE '%actor%')
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC, 
    mca.role_rank
LIMIT 100;
