WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS year_count
    FROM 
        aka_title AS t
    WHERE 
        t.kind_id IN (SELECT kt.id FROM kind_type AS kt WHERE kt.kind = 'feature')
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles,
        MAX(ct.kind) AS highest_role
    FROM 
        cast_info AS ci
    JOIN 
        comp_cast_type AS ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rk.keywords,
    mcd.company_names,
    mcd.company_types,
    ar.person_id,
    ar.unique_roles,
    ar.highest_role
FROM 
    RankedMovies AS rm
LEFT JOIN 
    MovieKeywords AS rk ON rm.movie_id = rk.movie_id
LEFT JOIN 
    MovieCompanyDetails AS mcd ON rm.movie_id = mcd.movie_id
LEFT JOIN 
    ActorRoleCounts AS ar ON rm.movie_id = (
        SELECT 
            ci.movie_id
        FROM 
            cast_info AS ci
        WHERE 
            ci.person_id = ar.person_id
        LIMIT 1
    )
WHERE 
    rm.rank <= 3 OR (ar.unique_roles IS NULL AND rm.year_count >= 5)
ORDER BY 
    rm.production_year DESC,
    rm.title ASC,
    ar.unique_roles DESC NULLS LAST;

