
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsWithRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.nr_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(aw.roles, 'No roles found') AS roles,
        COALESCE(mw.keywords, 'No keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            movie_id, 
            STRING_AGG(CONCAT(actor_name, '(', role_name, ')'), ', ') AS roles
        FROM 
            ActorsWithRoles
        GROUP BY 
            movie_id
    ) aw ON rm.movie_id = aw.movie_id
    LEFT JOIN MoviesWithKeywords mw ON rm.movie_id = mw.movie_id
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.roles,
    fb.keywords
FROM 
    FinalBenchmark fb
WHERE 
    fb.production_year = (SELECT MAX(production_year) FROM FinalBenchmark)
ORDER BY 
    fb.title ASC
LIMIT 10;
