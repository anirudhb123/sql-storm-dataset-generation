WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
NonFeatureMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id NOT IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
    HAVING 
        COUNT(c.id) > 1
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        pr.actor_name,
        pr.role_name
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PersonRoles pr ON rm.movie_id = pr.movie_id
)
SELECT 
    m.title,
    CASE 
        WHEN m.production_year IS NOT NULL THEN m.production_year
        ELSE 'Unknown Year'
    END AS output_year,
    COALESCE(m.actor_name, 'No Cast') AS actor_name,
    COALESCE(m.role_name, 'N/A') AS role_name,
    CASE 
        WHEN m.movie_id IS NOT NULL THEN 'Rank ' || CAST(m.movie_rank AS TEXT)
        ELSE 'Not Ranked'
    END AS rank_info
FROM 
    MoviesWithCast m
FULL OUTER JOIN 
    NonFeatureMovies nf ON m.movie_id = nf.movie_id
WHERE 
    (m.movie_rank IS NULL AND nf.movie_id IS NOT NULL) OR 
    (m.movie_rank IS NOT NULL AND m.movie_rank <= 3)
ORDER BY 
    output_year DESC NULLS LAST, 
    m.title ASC;

