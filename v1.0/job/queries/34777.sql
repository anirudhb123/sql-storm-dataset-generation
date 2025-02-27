WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        ml.movie_id 
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        ml.movie_id IN (SELECT id FROM aka_title WHERE kind_id = (SELECT id FROM kind_type WHERE kind = 'movie'))
)

SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COUNT(cc.id) AS total_cast_members,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
    COALESCE(COUNT(DISTINCT kw.keyword), 0) AS keyword_count,
    AVG(CASE 
        WHEN mt.production_year < 2000 THEN 5.0
        WHEN mt.production_year BETWEEN 2000 AND 2010 THEN 7.0
        ELSE 9.0 
        END) AS avg_rating_based_on_year
FROM 
    MovieHierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = h.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    aka_title mt ON mt.id = h.movie_id
GROUP BY 
    h.movie_id, h.title, h.production_year
HAVING 
    COUNT(cc.id) > 10 OR AVG(CASE 
        WHEN mt.production_year < 2000 THEN 5.0
        WHEN mt.production_year BETWEEN 2000 AND 2010 THEN 7.0
        ELSE 9.0 
    END) > 6.0
ORDER BY 
    h.production_year DESC,
    total_cast_members DESC;
