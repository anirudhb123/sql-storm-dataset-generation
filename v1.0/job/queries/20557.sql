WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        ct.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ak.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MoviesWithKeywords ak ON rm.movie_id = ak.movie_id
    WHERE 
        rm.title_rank <= 5
          AND rm.production_year >= 2000
)
SELECT 
    f.title,
    f.production_year,
    a.actor_name,
    COALESCE(a.role_type, 'Unknown Role') AS role_type,
    COUNT(DISTINCT a.role_rank) AS role_count
FROM 
    FilteredMovies f
LEFT JOIN 
    ActorRoles a ON f.movie_id = a.movie_id
WHERE 
    (f.keywords IS NULL OR f.keywords LIKE '%action%')
GROUP BY 
    f.title, f.production_year, a.actor_name, a.role_type
HAVING 
    COUNT(a.actor_name) > 0
ORDER BY 
    f.production_year DESC, f.title ASC;
