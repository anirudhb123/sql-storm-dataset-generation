
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, a.name, r.role
),
MoviesWithCompletions AS (
    SELECT 
        m.movie_id,
        COUNT(c.id) AS complete_count
    FROM 
        complete_cast m
    LEFT JOIN 
        complete_cast c ON m.movie_id = c.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cw.actor_name, 'No cast') AS cast_info,
    CAST(COALESCE(m.complete_count, 0) AS INTEGER) AS completions,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    RankedMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    CastWithRoles cw ON tm.title_id = cw.movie_id AND cw.role_count > 2
LEFT JOIN 
    MoviesWithCompletions m ON tm.title_id = m.movie_id
WHERE 
    (tm.rn <= 5 OR tm.rn BETWEEN 6 AND 10)
    AND (tm.title ILIKE '%action%' OR tm.title ILIKE '%drama%')
ORDER BY 
    completions DESC,
    tm.production_year ASC
LIMIT 100;
