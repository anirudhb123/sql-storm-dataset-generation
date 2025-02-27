WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL  -- Start with top-level movies (not episodes)
    
    UNION ALL
    
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
CastWithCount AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.id) AS cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
Top20Movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COALESCE(cc.cast_count, 0) AS cast_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastWithCount cc ON mh.movie_id = cc.movie_id
    ORDER BY 
        mh.production_year DESC, 
        cast_count DESC
    LIMIT 20
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    n.name AS director_name,
    COALESCE(info.info, 'No Information') AS director_bio,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE WHEN ci.role_id = 1 THEN 1 ELSE NULL END) AS avg_lead_roles
FROM 
    Top20Movies t
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id 
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
LEFT JOIN 
    person_info info ON info.person_id = n.person_id
GROUP BY 
    t.movie_id, n.name, info.info
ORDER BY 
    CAST_COUNT DESC, t.production_year DESC;
