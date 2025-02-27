WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        p.name AS actor_name,
        role.role AS role_type
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type role ON ci.role_id = role.id
    WHERE 
        role.role IN ('Actor', 'Actress')
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    m.title,
    m.production_year,
    COUNT(DISTINCT fc.actor_name) AS total_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MIN(m.title_rank) AS min_title_rank
FROM 
    RankedMovies m
LEFT JOIN 
    FilteredCast fc ON m.movie_id = fc.movie_id
LEFT JOIN 
    MovieKeywords k ON m.movie_id = k.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year
ORDER BY 
    total_cast DESC, m.production_year DESC;
