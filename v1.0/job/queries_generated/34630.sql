WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mk.movie_id,
        mk.linked_movie_id,
        1 AS depth
    FROM movie_link mk
    WHERE mk.movie_id IS NOT NULL

    UNION ALL
    
    SELECT 
        mh.movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.linked_movie_id = ml.movie_id
),

CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.person_role_id IS NOT NULL THEN ci.person_id END) AS with_roles
    FROM cast_info ci
    GROUP BY ci.movie_id
),

TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        COALESCE(ki.kind, 'N/A') AS kind
    FROM title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN kind_type ki ON t.kind_id = ki.id
)

SELECT 
    ti.title,
    ti.production_year,
    cs.total_cast,
    cs.with_roles,
    COUNT(DISTINCT mh.linked_movie_id) AS related_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM TitleInfo ti
LEFT JOIN CastStatistics cs ON ti.title_id = cs.movie_id
LEFT JOIN MovieHierarchy mh ON ti.title_id = mh.movie_id
LEFT JOIN movie_keyword mk ON ti.title_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE 
    (ti.production_year >= 2000 AND ti.production_year < 2023)
    OR (ti.title ILIKE '%action%' AND k.id IS NOT NULL)
GROUP BY 
    ti.title, ti.production_year, cs.total_cast, cs.with_roles
HAVING 
    COUNT(DISTINCT mh.linked_movie_id) > 1
ORDER BY 
    ti.production_year DESC, COUNT(DISTINCT mh.linked_movie_id) DESC;
