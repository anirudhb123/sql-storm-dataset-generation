WITH RECURSIVE RecursiveMovies AS (
    SELECT 
        m.id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m2.id,
        m2.title,
        m2.production_year,
        rm.depth + 1
    FROM 
        RecursiveMovies rm
    JOIN 
        movie_link ml ON ml.movie_id = rm.id
    JOIN 
        aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        rm.depth < 5
),
FilteredMovies AS (
    SELECT 
        r.*,
        ROW_NUMBER() OVER (PARTITION BY r.production_year ORDER BY r.depth DESC) AS rn
    FROM 
        RecursiveMovies r
)
SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year,
    COALESCE(aka.name, 'Unknown') AS actor_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    AVG(COALESCE(pi.info_type_id, 0)) AS avg_info_type_id
FROM 
    FilteredMovies m
LEFT JOIN 
    cast_info ci ON m.id = ci.movie_id
LEFT JOIN 
    aka_name aka ON ci.person_id = aka.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
WHERE 
    m.rn = 1
    AND (m.production_year IS NOT NULL)
GROUP BY 
    m.id, m.title, m.production_year, aka.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    m.production_year DESC, m.title;
