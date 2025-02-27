WITH FilteredMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role,
        COALESCE(NULLIF(aka.name, ''), cn.name) AS actor_name
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    LEFT JOIN 
        char_name cn ON ci.person_id = cn.imdb_id
),
MoviesWithRoles AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        cr.actor_name,
        ROW_NUMBER() OVER (PARTITION BY fm.movie_id ORDER BY cr.role) AS role_order
    FROM 
        FilteredMovies fm
    JOIN 
        CastRoles cr ON fm.movie_id = cr.movie_id
)
SELECT 
    m.title,
    m.production_year,
    STRING_AGG(DISTINCT m.actor_name || ' (' || COALESCE(m.role_order::text, 'N/A') || ')', ', ') AS actors,
    CASE 
        WHEN m.keywords IS NOT NULL THEN 
            CASE 
                WHEN 'thriller' = ANY(m.keywords) THEN 'Thriller'
                ELSE 'Other'
            END
        ELSE 'Unknown Genre'
    END AS genre_classification
FROM 
    MoviesWithRoles m
GROUP BY 
    m.title, m.production_year
HAVING 
    COUNT(DISTINCT m.actor_name) > 3
ORDER BY 
    m.production_year DESC, m.title;
