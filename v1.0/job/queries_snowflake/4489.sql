
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfoWithRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    ci.actor_count,
    mci.company_names,
    mci.company_types,
    COALESCE(ci.actor_count, 0) AS total_actors,
    CASE 
        WHEN MAX(rm.title_rank) <= 5 THEN 'Top Titles'
        ELSE 'Other Titles'
    END AS title_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastInfoWithRoles ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ci.actor_count, mci.company_names, mci.company_types
ORDER BY 
    rm.production_year DESC, rm.title;
