WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (
            SELECT id FROM kind_type WHERE kind = 'movie'
        )

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    COALESCE(dp.average_duration, 'Not Available') AS average_duration,
    COALESCE(aw.actor_count, 0) AS actor_count,
    ARRAY_AGG(DISTINCT c.name) AS companies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieHierarchy m
LEFT JOIN 
    (SELECT 
         movie_id, 
         AVG(DISTINCT mi.info::numeric) AS average_duration
     FROM 
         movie_info mi
     WHERE 
         mi.info_type_id = (SELECT id FROM info_type WHERE info = 'duration')
     GROUP BY 
         movie_id
    ) dp ON m.movie_id = dp.movie_id
LEFT JOIN 
    (SELECT 
         ci.movie_id, 
         COUNT(DISTINCT ci.person_id) AS actor_count
     FROM 
         cast_info ci
     GROUP BY 
         ci.movie_id
    ) aw ON m.movie_id = aw.movie_id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND (m.title ILIKE '%adventure%' OR m.title ILIKE '%action%')
GROUP BY 
    m.movie_id, m.title, dp.average_duration, aw.actor_count
ORDER BY 
    m.production_year DESC, actor_count DESC
LIMIT 50;
