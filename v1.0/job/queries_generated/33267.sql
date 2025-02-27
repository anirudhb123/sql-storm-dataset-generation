WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        ARRAY[m.title] AS path,
        1 AS level
    FROM 
        aka_title m 
    WHERE 
        m.episode_of_id IS NULL
    UNION ALL
    SELECT 
        m.id AS movie_id, 
        m.title, 
        path || m.title,
        level + 1
    FROM 
        aka_title m 
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
ranked_cast AS (
    SELECT 
        c.person_id, 
        c.movie_id, 
        r.role, 
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rn
    FROM 
        cast_info c 
    JOIN 
        role_type r ON c.role_id = r.id
),
company_with_roles AS (
    SELECT 
        mc.movie_id,
        cm.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT rc.person_id) AS role_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cm ON mc.company_id = cm.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        ranked_cast rc ON mc.movie_id = rc.movie_id
    GROUP BY 
        mc.movie_id, cm.name, ct.kind
),
genre_with_keywords AS (
    SELECT 
        mt.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
movies_summary AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        COALESCE(g.keywords, '{}') AS keywords,
        COALESCE(cwr.company_name, 'None') AS company_name,
        COALESCE(cwr.role_count, 0) AS role_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        company_with_roles cwr ON mh.movie_id = cwr.movie_id
    LEFT JOIN 
        genre_with_keywords g ON mh.movie_id = g.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.level,
    ms.keywords,
    ms.company_name,
    ms.role_count,
    COUNT(mk.keyword_id) AS total_keywords,
    SUM(CASE WHEN cs.link_type = 'similar' THEN 1 ELSE 0 END) AS similar_movies_count
FROM 
    movies_summary ms
LEFT JOIN 
    movie_link ml ON ms.movie_id = ml.movie_id
LEFT JOIN 
    link_type cs ON ml.link_type_id = cs.id
LEFT JOIN 
    movie_keyword mk ON ms.movie_id = mk.movie_id
GROUP BY 
    ms.movie_id, ms.title, ms.level, ms.keywords, ms.company_name, ms.role_count
ORDER BY 
    ms.level DESC, total_keywords DESC;
