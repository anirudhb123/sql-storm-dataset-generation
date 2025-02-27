WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsWithRoles AS (
    SELECT 
        ka.person_id,
        ka.name,
        ri.role,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        role_type ri ON ci.role_id = ri.id
    GROUP BY 
        ka.person_id, ka.name, ri.role
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    r.title,
    r.production_year,
    a.name AS actor_name,
    a.role,
    COALESCE(mw.keywords, '{}') AS keywords
FROM 
    RankedTitles r
LEFT JOIN 
    ActorsWithRoles a ON r.rank = 1 AND a.movie_count > 5
LEFT JOIN 
    MoviesWithKeywords mw ON r.title_id = mw.movie_id
WHERE 
    r.production_year > 2000
ORDER BY 
    r.production_year DESC, r.title;
