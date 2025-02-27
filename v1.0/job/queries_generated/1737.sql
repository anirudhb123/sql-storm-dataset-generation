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
ActorRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MoviesWithKeywords AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        ar.role,
        ar.actor_count
    FROM 
        RankedMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.title_id = mk.movie_id
    LEFT JOIN 
        ActorRoles ar ON tm.title_id = ar.movie_id
)

SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    mwk.role,
    mwk.actor_count,
    CASE 
        WHEN mwk.actor_count IS NULL THEN 'No cast information'
        WHEN mwk.actor_count > 5 THEN 'Large cast'
        ELSE 'Standard cast'
    END AS cast_size
FROM 
    MoviesWithKeywords mwk
WHERE 
    mwk.production_year >= 2000
ORDER BY 
    mwk.production_year DESC, mwk.actor_count DESC;
