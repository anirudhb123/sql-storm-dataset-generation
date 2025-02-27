WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.season_nr,
        t.episode_nr,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        m.season_nr,
        m.episode_nr,
        h.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.movie_id
    JOIN 
        MovieHierarchy h ON ml.linked_movie_id = h.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(CAST(SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id), 'INTEGER'), 0) AS female_count,
    COALESCE(CAST(SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id), 'INTEGER'), 0) AS male_count,
    COALESCE(CAST(COUNT(DISTINCT c.role_id) OVER (PARTITION BY mh.movie_id), 'INTEGER'), 0) AS distinct_roles,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    mh.level AS movie_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    person_info p ON ci.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY 
    mh.production_year DESC, movie_count DESC;
