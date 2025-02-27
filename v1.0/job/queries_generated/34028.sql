WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL

    UNION ALL
    
    -- Recursive case: Join with movie_link to find sequels/prequels
    SELECT 
        ml.linked_movie_id AS movie_id, 
        t.title, 
        t.production_year, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title t ON ml.movie_id = t.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(c.name, 'Unknown') AS company_name,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(mi.info_type_id) AS avg_info_type_id,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY m.production_year DESC) AS rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    m.movie_id, m.title, m.production_year, company_name
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    m.production_year DESC, 
    total_cast DESC
LIMIT 10;
