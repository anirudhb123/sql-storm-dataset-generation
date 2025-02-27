WITH RECURSIVE MovieTree AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mt.level + 1
    FROM
        movie_link ml
    JOIN
        MovieTree mt ON ml.movie_id = mt.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    mt.title AS movie_title,
    mt.production_year AS year,
    COUNT(DISTINCT ci.person_id) AS num_cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    AVG(COALESCE(m_info.info::int, 0)) AS avg_rating,
    SUM(CASE 
        WHEN m_comp.company_type_id IS NOT NULL THEN 1 
        ELSE 0 
    END) AS num_companies
FROM 
    MovieTree mt
LEFT JOIN 
    complete_cast cc ON mt.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mt.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_info m_info ON mt.movie_id = m_info.movie_id 
        AND m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    movie_companies m_comp ON mt.movie_id = m_comp.movie_id
GROUP BY 
    mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    avg_rating DESC NULLS LAST, 
    num_cast DESC;
