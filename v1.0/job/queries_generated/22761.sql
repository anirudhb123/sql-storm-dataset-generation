WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
ActorRoles AS (
    SELECT 
        a.name,
        c.movie_id,
        r.role
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        mk.keywords,
        ARRAY_AGG(DISTINCT ar.name ORDER BY ar.name) AS actor_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.title = mk.title
    LEFT JOIN 
        ActorRoles ar ON rm.title = ar.title
    WHERE 
        rm.rank_by_cast <= 5
    GROUP BY 
        rm.title, rm.production_year, mk.keywords
)
SELECT 
    COALESCE(tm.title, 'Unknown Title') AS title,
    COALESCE(tm.production_year, 0) AS production_year,
    COALESCE(tm.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tm.actor_names IS NULL THEN 'No Actors'
        ELSE ARRAY_TO_STRING(tm.actor_names, ', ')
    END AS actor_names
FROM 
    TopMovies tm
FULL OUTER JOIN 
    aka_title t ON tm.title = t.title AND tm.production_year = t.production_year
WHERE 
    (tm.actor_names IS NOT NULL OR t.title IS NULL)

ORDER BY 
    production_year DESC, title;
