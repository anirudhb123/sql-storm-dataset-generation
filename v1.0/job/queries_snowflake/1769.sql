
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COALESCE(ri.role, 'Unknown') AS role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type ri ON ci.role_id = ri.id
    GROUP BY 
        ci.movie_id, ri.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title AS MovieTitle,
    rm.production_year,
    cr.role AS PrimaryRole,
    mk.keywords AS AssociatedKeywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rm.title_id) AS total_complete_cast,
    (SELECT COUNT(DISTINCT ci.person_id) FROM cast_info ci WHERE ci.movie_id = rm.title_id AND ci.note IS NULL) AS total_non_noted_cast
FROM 
    RankedMovies rm
LEFT JOIN 
    CastInfoWithRoles cr ON rm.title_id = cr.movie_id AND cr.role_count > 1
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, MovieTitle;
