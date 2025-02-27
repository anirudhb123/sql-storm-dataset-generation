WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id, 
        m.title, 
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
actor_info AS (
    SELECT 
        a.person_id,
        n.name AS actor_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    LEFT JOIN 
        movie_keyword k ON c.movie_id = k.movie_id
    GROUP BY 
        a.person_id, n.name
),
top_actors AS (
    SELECT 
        actor_name, 
        movie_count, 
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        actor_info
    WHERE 
        movie_count > 5
),
company_movies AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ta.actor_name,
    ta.movie_count,
    cm.company_name,
    cm.company_type,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year >= 2000 AND mh.production_year <= 2010 THEN 'Modern'
        ELSE 'Contemporary' 
    END AS era,
    COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
LEFT JOIN 
    top_actors ta ON mh.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ta.person_id)
LEFT JOIN 
    company_movies cm ON mh.movie_id = cm.movie_id
LEFT JOIN 
    movie_keyword k ON mh.movie_id = k.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ta.actor_name, ta.movie_count, cm.company_name, cm.company_type
ORDER BY 
    mh.production_year DESC, ta.movie_count DESC
LIMIT 50;

