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
ActorRoles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
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
),
MoviesWithActors AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        a.actor_name,
        a.role
    FROM 
        RankedMovies m
    LEFT JOIN 
        ActorRoles a ON m.movie_id = a.movie_id
)
SELECT 
    ma.title,
    ma.production_year,
    COALESCE(STRING_AGG(DISTINCT ma.actor_name || ' as ' || ma.role), 'No Cast') AS cast_details,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords
FROM 
    MoviesWithActors ma 
LEFT JOIN 
    MovieKeywords mk ON ma.movie_id = mk.movie_id
WHERE 
    ma.production_year = (SELECT MAX(production_year) FROM RankedMovies)
GROUP BY 
    ma.title, 
    ma.production_year
HAVING 
    COUNT(ma.actor_name) > 0 
    OR EXISTS (
        SELECT 1 FROM MovieKeywords mk2 WHERE mk2.movie_id = ma.movie_id AND mk2.keywords IS NOT NULL
    )
ORDER BY 
    ma.title ASC;

-- This query showcases multiple SQL constructs:
-- 1. CTEs (Common Table Expressions) to structure the query into digestible parts.
-- 2. Window functions to rank movies by production year.
-- 3. Outer joins to combine various datasets even when there are missing values.
-- 4. String aggregation to collate actor details and keywords into single fields.
-- 5. Complicated predicates in the WHERE and HAVING clauses to filter the results based on conditions.
-- 6. Use of COALESCE to handle NULL values elegantly in the output.
