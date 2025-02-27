WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        ai.name AS actor_name,
        ci.kind AS person_role
    FROM 
        cast_info c
    JOIN 
        aka_name ai ON c.person_id = ai.person_id
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    fc.actor_name,
    fc.person_role,
    COUNT(fc.actor_name) OVER (PARTITION BY rm.movie_id) AS total_cast,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     WHERE mc.movie_id = rm.movie_id) AS total_companies,
    COALESCE((SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
              FROM movie_keyword mk 
              JOIN keyword k ON mk.keyword_id = k.id 
              WHERE mk.movie_id = rm.movie_id), 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCast fc ON rm.movie_id = fc.movie_id
WHERE 
    rm.rank_title <= 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
