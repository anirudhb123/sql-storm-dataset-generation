WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    UNION ALL
    SELECT 
        m.linked_movie_id,
        t.title,
        t.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link m ON mh.movie_id = m.movie_id
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    SOLR.score AS relevance_score,
    CASE WHEN r.role IS NULL THEN 'Unknown Role' ELSE r.role END AS role,
    COALESCE(mi.info, 'No info available') AS movie_info,
    COUNT(DISTINCT mc.company_id) AS production_company_count,
    MAX(t.production_year) AS latest_movie_year,
    AVG(COALESCE(CAST(SUBSTRING(k.keyword FROM '^[0-9]{1,4}') AS INTEGER), 0)) AS avg_keyword_length
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy h ON ci.movie_id = h.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_info mi ON h.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
LEFT JOIN 
    movie_companies mc ON h.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.name, t.title, r.role, mi.info, h.depth
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 
ORDER BY 
    relevance_score DESC, latest_movie_year DESC, avg_keyword_length DESC;

