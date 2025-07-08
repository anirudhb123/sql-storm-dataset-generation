
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        c.person_role_id,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id, c.person_role_id
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ar.role_count, 0) AS total_roles,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = rm.movie_id AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')) AS production_companies,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = rm.movie_id 
       AND ci.note IS NULL) AS distinct_actors
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
