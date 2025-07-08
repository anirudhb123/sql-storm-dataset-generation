
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_in_year
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.person_id,
        c.movie_id,
        r.role,
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS total_cast_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS casting_order,
        COALESCE(pr.name, 'Unknown') AS person_name
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        aka_name pr ON c.person_id = pr.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        COUNT(DISTINCT mc.company_type_id) AS distinct_company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
UniqueKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS unique_keyword_count 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    cd.person_name,
    cd.role,
    cd.total_cast_count,
    mk.unique_keyword_count,
    mc.companies,
    CAST(CASE 
        WHEN cd.casting_order = 1 THEN 'Lead Actor'
        WHEN cd.casting_order <= 5 THEN 'Supporting Cast'
        ELSE 'Minor Role'
    END AS varchar) AS casting_role,
    COALESCE(cd.role, 'No Role Assigned') AS role_assigned
FROM 
    RankedMovies rm
JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
JOIN 
    UniqueKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.movie_id = mc.movie_id
WHERE 
    cd.total_cast_count > 0
    AND rm.rank_in_year <= 5
    AND mk.unique_keyword_count IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.title;
