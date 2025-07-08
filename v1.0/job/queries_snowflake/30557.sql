WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level 
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    UNION ALL
    SELECT 
        t.id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        a.person_id,
        a.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.nr_order) AS role_rank
    FROM 
        cast_info a
    JOIN 
        role_type r ON a.role_id = r.id
),
MovieInfoWithKeywords AS (
    SELECT 
        m.movie_id,
        m.info,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_info m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id, m.info
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ARRAY_AGG(DISTINCT CONCAT(a.name, ' (', ar.role, ')')) AS actors,
    MIN(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN mi.info END) AS rating,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords,
    mh.level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    ActorRoles ar ON a.person_id = ar.person_id AND ar.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT a.id) > 0
ORDER BY 
    mh.production_year DESC, mh.movie_id;