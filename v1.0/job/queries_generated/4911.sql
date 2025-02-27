WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(cr.role) AS primary_role
    FROM 
        cast_info ci
    JOIN 
        role_type cr ON ci.role_id = cr.id
    GROUP BY 
        ci.person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MoviesWithCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ak.name AS actor_name,
    ar.primary_role,
    mk.keywords,
    COALESCE(mwc.company_count, 0) AS companies_involved,
    ar.movie_count AS total_movies_appeared
FROM 
    RankedTitles rt
JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    ActorRoleCounts ar ON ci.person_id = ar.person_id
LEFT JOIN 
    MoviesWithKeywords mk ON rt.title_id = mk.movie_id
LEFT JOIN 
    MoviesWithCompanies mwc ON rt.title_id = mwc.movie_id
WHERE 
    rt.year_rank = 1
    AND ar.movie_count > 5
    AND ak.name IS NOT NULL
ORDER BY 
    rt.production_year DESC, 
    ak.name;
