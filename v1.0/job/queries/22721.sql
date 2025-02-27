WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    UNION ALL
    SELECT 
        t.id,
        t.title, 
        t.production_year,
        t.kind_id,
        th.depth + 1
    FROM 
        aka_title t
    JOIN 
        title_hierarchy th ON th.id = t.episode_of_id
    WHERE 
        th.depth < 5
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
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
),
movie_info_summary AS (
    SELECT 
        m.movie_id,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN mi.info END) AS rating,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Duration') THEN mi.info END) AS duration
    FROM 
        movie_info m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    th.title AS episode_title,
    th.production_year,
    cs.actor_count,
    cs.cast_names,
    mk.keywords,
    mis.rating,
    mis.duration,
    CASE 
        WHEN cs.actor_count IS NULL THEN 'No Cast'
        WHEN cs.actor_count > 5 THEN 'Large Cast'
        ELSE 'Small Cast' 
    END AS cast_size,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN 'Keywords Available'
        ELSE 'No Keywords' 
    END AS keyword_info
FROM 
    title_hierarchy th
LEFT JOIN 
    cast_summary cs ON th.id = cs.movie_id
LEFT JOIN 
    movie_keywords mk ON th.id = mk.movie_id
LEFT JOIN 
    movie_info_summary mis ON th.id = mis.movie_id
WHERE 
    th.production_year >= 2000
    AND (mis.rating IS NOT NULL OR mis.duration IS NOT NULL)
ORDER BY 
    th.production_year DESC, 
    th.title;
