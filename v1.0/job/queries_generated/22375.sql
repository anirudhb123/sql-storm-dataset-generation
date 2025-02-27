WITH RECURSIVE movie_series AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'series')
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        ms.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        movie_series ms ON t.episode_of_id = ms.title_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind IN ('episode', 'special'))
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id, ci.role_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(c.actor_count, 0) AS total_actors,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No Cast') AS actors
    FROM 
        aka_title m
    LEFT JOIN 
        cast_roles c ON m.id = c.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        m.production_year BETWEEN 1980 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    md.title AS movie_title,
    md.production_year,
    md.total_actors,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    ms.level AS series_level
FROM 
    movie_details md
LEFT JOIN 
    movie_keywords mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    movie_series ms ON md.movie_id = ms.title_id
WHERE 
    md.total_actors > 0
ORDER BY 
    md.production_year DESC, 
    md.total_actors DESC,
    ms.level ASC;
