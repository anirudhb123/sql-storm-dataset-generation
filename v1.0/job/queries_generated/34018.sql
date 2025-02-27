WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mg.name, 'Independent') AS production_company,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name mg ON mc.company_id = mg.id

    UNION ALL

    SELECT 
        m.id,
        m.title,
        COALESCE(mg.name, 'Independent') AS production_company,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_company,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE NULL END) AS female_ratio,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    name p ON c.person_id = p.imdb_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
GROUP BY 
    mh.movie_id, mh.title, mh.production_company, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    mh.production_year DESC, total_cast DESC;
