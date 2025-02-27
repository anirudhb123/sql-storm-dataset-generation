WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY[m.title] AS path
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.path || e.title
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
final_benchmark AS (
    SELECT
        mh.movie_id,
        mh.title AS movie_title,
        mh.production_year,
        cr.roles,
        mwk.keywords,
        COALESCE(COUNT(r.id), 0) AS total_cast,
        jsonb_build_object('cast', ARRAY_AGG(DISTINCT a.name ORDER BY a.name)) AS cast_names
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        cast_roles cr ON mh.movie_id = cr.movie_id
    LEFT JOIN 
        movies_with_keywords mwk ON mh.movie_id = mwk.movie_id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = mh.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') 
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = mh.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, cr.roles, mwk.keywords
)
SELECT 
    *,
    CASE 
        WHEN total_cast > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_info,
    ARRAY_LENGTH(keywords, 1) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS row_num
FROM 
    final_benchmark
ORDER BY 
    production_year DESC, total_cast DESC, movie_title;
