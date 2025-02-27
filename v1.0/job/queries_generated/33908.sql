WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m2.id AS movie_id,
        m2.title AS movie_title,
        mh.level + 1
    FROM 
        aka_title m2
    JOIN 
        movie_link ml ON m2.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        m2.production_year >= 2000
),
AdvancedCast AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS appearance_count,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT movie_id FROM MovieHierarchy)
    GROUP BY 
        c.person_id, a.name
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    mh.movie_title,
    mh.level,
    ac.actor_name,
    ac.appearance_count,
    COALESCE(mk.keywords, 'No keywords found') AS associated_keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    AdvancedCast ac ON mh.movie_id = ac.movie_id AND ac.rank = 1
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.level <= 3
ORDER BY 
    mh.level, ac.appearance_count DESC, mh.movie_title;
