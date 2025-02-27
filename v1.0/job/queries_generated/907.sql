WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 10
),
PersonRoleCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    INNER JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id
),
MoviesWithRoles AS (
    SELECT 
        tm.title,
        prc.roles,
        prc.movie_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = tm.movie_id
    LEFT JOIN 
        PersonRoleCounts prc ON cc.subject_id = prc.person_id
),
MovieCompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        MAX(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END) AS has_distributor
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mw.title,
    mw.roles,
    mw.movie_count,
    mcs.company_count,
    CASE 
        WHEN mcs.has_distributor = 1 THEN 'Yes'
        ELSE 'No'
    END AS has_distributor
FROM 
    MoviesWithRoles mw
LEFT JOIN 
    MovieCompanyStats mcs ON mw.title = mcs.movie_id
WHERE 
    mw.movie_count > 2
ORDER BY 
    mw.production_year DESC, 
    mw.movie_count DESC;
