WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        ct.kind AS role_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    GROUP BY 
        a.name, ct.kind
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MoviesWithDetails AS (
    SELECT 
        r.title,
        r.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        ar.actor_name,
        ar.role_name,
        ar.movie_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        MovieKeywords mk ON r.id = mk.movie_id
    LEFT JOIN 
        ActorRoles ar ON r.title = ar.actor_name
    WHERE 
        r.rn <= 5
)
SELECT 
    mw.title,
    mw.production_year,
    NULLIF(mw.keywords, 'No Keywords') AS keywords_used,
    COALESCE(mw.actor_name, 'Unknown Actor') AS actor,
    mw.role_name,
    CASE 
        WHEN mw.movie_count IS NULL THEN 'No Roles'
        ELSE mw.movie_count::text || ' Roles'
    END AS role_summary
FROM 
    MoviesWithDetails mw
WHERE 
    mw.production_year > (SELECT AVG(production_year) FROM aka_title) 
    OR mw.actor_name IS NOT NULL
ORDER BY 
    mw.production_year DESC, mw.title ASC
LIMIT 100;
