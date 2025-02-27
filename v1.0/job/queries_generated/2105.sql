WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast,
        COALESCE(SUM(CASE WHEN ci.kind_id IS NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id), 0) AS undefined_roles
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.undefined_roles,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC
LIMIT 10;
