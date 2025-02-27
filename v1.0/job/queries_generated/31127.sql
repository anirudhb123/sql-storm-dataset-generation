WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        NULL::INTEGER AS parent_id,
        1 AS lvl
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        h.movie_id AS parent_id,
        h.lvl + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy h ON m.episode_of_id = h.movie_id
),
cast_summary AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS cast_names,
        MAX(ak.name) AS lead_actor
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keyword_summary AS (
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
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        coalesce(c.total_cast, 0) AS total_cast,
        coalesce(k.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN m.production_year >= 2000 THEN 'Modern'
            WHEN m.production_year >= 1980 THEN 'Classic'
            ELSE 'Old'
        END AS era
    FROM 
        aka_title m
    LEFT JOIN 
        cast_summary c ON m.id = c.movie_id
    LEFT JOIN 
        keyword_summary k ON m.id = k.movie_id
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind='movie')
)
SELECT 
    mh.lvl,
    mh.title,
    md.production_year,
    md.total_cast,
    md.keywords,
    md.era,
    ARRAY_AGG(DISTINCT ch.name) AS child_titles
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_details md ON mh.movie_id = md.movie_id
LEFT JOIN 
    movie_hierarchy ch ON mh.movie_id = ch.parent_id
GROUP BY 
    mh.lvl, mh.title, md.production_year, md.total_cast, md.keywords, md.era
ORDER BY 
    mh.lvl, md.production_year DESC;
