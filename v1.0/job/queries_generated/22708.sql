WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title AS movie_title,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA'
    
    UNION ALL
    
    SELECT 
        m.id,
        mh.movie_title || ' (Sequel)',
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5  -- Limiting the hierarchy to 5 levels to avoid too deep recursion
)
, ActorCounts AS (
    SELECT 
        ai.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    GROUP BY 
        ai.person_id
)
, TitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.kind_id
)

SELECT 
    mh.movie_title,
    mh.level,
    td.title AS original_title,
    CASE WHEN td.rn IS NOT NULL THEN 'Has Keywords' ELSE 'No Keywords' END AS keyword_status,
    COUNT(DISTINCT ac.person_id) AS actor_count,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS conditions_met_count 
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TitleDetails td ON mh.movie_id = td.title_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    ActorCounts ac ON ci.person_id = ac.person_id
GROUP BY 
    mh.movie_title, mh.level, td.title, td.rn
HAVING 
    COUNT(DISTINCT ac.person_id) > 0 
    AND (mh.level % 2 = 0 OR keyword_status = 'No Keywords')  -- Bizarre condition including MOD logic
ORDER BY 
    mh.level ASC, actor_count DESC;
