WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

TopMovies AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        ROW_NUMBER() OVER (ORDER BY m.movie_id DESC) AS rank
    FROM 
        MovieHierarchy m
    WHERE 
        m.level = 1
    LIMIT 10
)

SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    c.role_id,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = t.id) AS total_cast,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    CASE 
        WHEN mci.note IS NOT NULL THEN 'Noted'
        ELSE 'No Note'
    END AS company_note_status
FROM 
    TopMovies tm
JOIN 
    title t ON tm.movie_id = t.id
LEFT JOIN 
    cast_info c ON c.movie_id = t.id
LEFT JOIN 
    aka_name ak ON ak.person_id = c.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.id
LEFT JOIN 
    movie_info_idx mii ON mii.movie_id = t.id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = t.id
LEFT JOIN 
    movie_info mci ON mci.movie_id = t.id AND mci.info_type_id = (SELECT id FROM info_type WHERE info = 'Note')
GROUP BY 
    t.id, ak.name, c.role_id, mci.note
ORDER BY 
    total_cast DESC, movie_title;
