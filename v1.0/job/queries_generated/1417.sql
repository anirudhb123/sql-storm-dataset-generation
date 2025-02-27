WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
), 
MovieKeywords AS (
    SELECT 
        at.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.title
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, rt.role
    HAVING 
        COUNT(*) > 1
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    mk.keywords,
    pr.role,
    pr.role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.title = mk.title
LEFT JOIN 
    PersonRoles pr ON rm.cast_count > 5 AND pr.role IS NOT NULL
WHERE 
    rm.rank <= 5 OR mk.keywords IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
