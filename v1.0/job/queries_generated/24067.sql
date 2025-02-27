WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        NULLIF(k.keyword, '') AS keyword,
        NULLIF(cast.person_id, 0) AS main_actor_id,
        ROW_NUMBER() OVER(PARTITION BY m.id ORDER BY c.nr_order) AS actor_order
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info AS cast ON m.id = cast.movie_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        k.keyword,
        mh.main_actor_id,
        mh.actor_order
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS linked ON ml.linked_movie_id = linked.id
    LEFT JOIN 
        movie_keyword AS mk ON linked.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        mh.actor_order < (SELECT COUNT(*) FROM cast_info WHERE movie_id = mh.movie_id)  -- avoid infinite loops
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT mh.main_actor_id) AS actor_count,
    STRING_AGG(DISTINCT mh.keyword, ', ') AS keywords,
    SUM(CASE WHEN mh.actor_order = 1 THEN 1 ELSE 0 END) AS lead_actor_count,
    STRING_AGG(DISTINCT n.name, '; ') AS actor_names,
    COALESCE(MAX(c.country_code), 'UNKNOWN') AS main_actor_country
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    cast_info AS c ON mh.main_actor_id = c.person_id
LEFT JOIN 
    aka_name AS n ON n.person_id = c.person_id
LEFT JOIN 
    company_name AS c_n ON c_n.imdb_id = c.movie_id
WHERE 
    mh.production_year > 2000
    AND (mh.keyword IS NULL OR mh.keyword LIKE '%Horror%')
    AND (mh.production_year > 2010 OR mh.production_year < 1990)
GROUP BY 
    mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mh.main_actor_id) > 1
ORDER BY 
    mh.production_year DESC, actor_count DESC
LIMIT 50;
