WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        t.kind_id,
        m.epidode_of_id,
        m.season_nr,
        m.episode_nr
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.imdb_id
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.kind_id,
        mh.episode_of_id,
        mh.season_nr,
        mh.episode_nr
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    WHERE 
        ml.link_type_id IN (SELECT id FROM link_type WHERE link = 'remake')
)

SELECT 
    p.person_id,
    a.name AS person_name,
    m.movie_title,
    m.production_year,
    COUNT(CASE WHEN mc.company_id IS NOT NULL THEN 1 END) AS companies_involved,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_kinds,
    ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY m.production_year DESC) AS movie_rank
FROM 
    MovieHierarchy m
JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info pi ON pi.person_id = a.person_id
WHERE 
    pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'Feature Film')
    AND m.production_year IS NOT NULL
    AND a.name IS NOT NULL
GROUP BY 
    p.person_id, a.name, m.movie_title, m.production_year
ORDER BY 
    movie_rank ASC, production_year DESC;
