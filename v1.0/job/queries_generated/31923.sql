WITH RECURSIVE movie_relationships AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1 -- Assuming 1 corresponds to movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_relationships mr ON ml.movie_id = mr.movie_id
    WHERE 
        mr.level < 3 -- Limit the depth of recursion
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    COALESCE(mem.info, 'No additional info') AS movie_info,
    COUNT(*) OVER (PARTITION BY ak.name) AS movie_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mem ON ci.movie_id = mem.movie_id
JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_relationships mt ON ci.movie_id = mt.movie_id
WHERE 
    mt.level = 1 -- Only direct relations
    AND (ci.note IS NULL OR ci.note <> 'uncredited')
GROUP BY 
    ak.name, mt.title, mem.info
ORDER BY 
    movie_count DESC, ak.name;

