WITH RECURSIVE movie_series AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        ms.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        movie_series ms ON t.episode_of_id = ms.movie_id
),
cast_with_roles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ms.title AS movie_title,
    ms.production_year,
    ms.season_nr,
    ms.episode_nr,
    COALESCE(cw.actor_name, 'Unknown Actor') AS lead_actor,
    COALESCE(cw.actor_role, 'Unknown Role') AS role,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = ms.movie_id) AS total_cast_members,
    CASE 
        WHEN ms.level > 0 THEN 'Episode'
        ELSE 'Feature'
    END AS movie_type
FROM 
    movie_series ms
LEFT JOIN 
    cast_with_roles cw ON ms.movie_id = cw.movie_id AND cw.actor_rank = 1
LEFT JOIN 
    movie_keywords mk ON ms.movie_id = mk.movie_id
WHERE 
    ms.production_year >= 2000
ORDER BY 
    ms.production_year DESC, ms.title;
