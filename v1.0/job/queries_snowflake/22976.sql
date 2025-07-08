
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movies_in_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS distinct_roles,
        LISTAGG(DISTINCT c.kind, ', ') WITHIN GROUP (ORDER BY c.kind) AS role_kinds
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
    COALESCE(ar.distinct_roles, 0) AS distinct_role_count,
    COALESCE(mk.keyword_count, 0) AS keyword_count,
    ar.role_kinds,
    CASE 
        WHEN rm.movies_in_year > 1 THEN 'Multi-Movie-Year'
        ELSE 'Single Movie Year'
    END AS year_category,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = rm.movie_id)) AS total_cast
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.title_rank <= 5
    AND (
        (rm.production_year < 2000 AND (COALESCE(ar.distinct_roles, 0) > 1 OR mk.keyword_count IS NULL)) 
        OR (rm.production_year >= 2000 AND mk.keyword_count > 5)
    )
ORDER BY 
    rm.production_year DESC, 
    rm.title;
