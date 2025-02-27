WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.season_nr IS NULL
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
ActorInfo AS (
    SELECT 
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(CASE WHEN coalesce(ki.keyword, '') != '' THEN 1 ELSE 0 END) AS keyword_appeared
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        a.name
),
CompanyStats AS (
    SELECT 
        cn.name AS company_name,
        COUNT(mc.movie_id) AS total_movies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords
    FROM 
        company_name cn
    JOIN 
        movie_companies mc ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        cn.name
)
SELECT 
    mh.title,
    mh.production_year,
    ai.name AS actor_name,
    ai.movie_count AS movies_featuring_actor,
    ROUND(ai.keyword_appeared * 100, 2) AS keyword_percentage,
    cs.total_movies AS company_movies,
    cs.associated_keywords 
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    ActorInfo ai ON an.name = ai.name
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    CompanyStats cs ON mc.company_id = cs.company_name
WHERE 
    mh.production_year >= 2000
    AND mh.level = 1
    AND (ci.note IS NULL OR ci.note LIKE '%featured%')
ORDER BY 
    mh.production_year DESC, ai.movie_count DESC;
