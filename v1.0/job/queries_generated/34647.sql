WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    a.name AS actor_name,
    COUNT(DISTINCT rc.person_id) AS number_of_actors,
    MAX(mr.info) AS rating_info,
    STRING_AGG(DISTINCT pc.info, ', ') AS production_companies
FROM 
    MovieHierarchy m
LEFT JOIN 
    cast_info ci ON ci.movie_id = m.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN 
    company_name c ON c.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id
LEFT JOIN 
    info_type it ON it.id = mi.info_type_id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id
LEFT JOIN 
    movie_info_idx mr ON mr.movie_id = m.movie_id AND mr.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    (SELECT 
         company_id, 
         STRING_AGG(CASE 
                        WHEN name IS NULL THEN 'Unknown Company' 
                        ELSE name 
                    END, ', ') AS info 
     FROM 
         company_name 
     GROUP BY 
         company_id) pc ON pc.company_id = mc.company_id
WHERE 
    m.production_year >= 2000
    AND m.production_year <= EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY 
    m.id, m.title, m.production_year, c.name, k.keyword, a.name
ORDER BY 
    m.production_year DESC, movie_title;
