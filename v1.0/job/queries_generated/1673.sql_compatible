
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS actor_role,
        t.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
),
GatheredInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        COALESCE(SUM(CASE WHEN mi.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.rank = 1
    GROUP BY 
        m.movie_id, m.title
)

SELECT 
    gi.title,
    gi.info_count,
    ARRAY_LENGTH(gi.keywords, 1) AS keyword_count,
    aw.actor_name,
    aw.actor_role
FROM 
    GatheredInfo gi
LEFT JOIN 
    ActorsWithRoles aw ON gi.title = aw.movie_title AND aw.role_rank = 1
WHERE 
    gi.info_count > 0
ORDER BY 
    gi.title, gi.info_count DESC
LIMIT 10;
