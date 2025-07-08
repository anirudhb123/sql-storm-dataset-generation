
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    t.title, 
    t.production_year, 
    a.actor_name, 
    a.role, 
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    RANK() OVER (ORDER BY t.production_year DESC) AS year_rank
FROM 
    RankedTitles t
LEFT JOIN 
    ActorRoles a ON t.title_id = a.movie_id
LEFT JOIN 
    MoviesWithKeywords k ON t.title_id = k.movie_id
WHERE 
    (a.role_count > 1 OR a.actor_name IS NULL)
ORDER BY 
    t.production_year DESC, t.title;
