WITH RECURSIVE RelatedMovies AS (
    SELECT 
        m.id as movie_id,
        m.title,
        m.production_year,
        1 as level
    FROM 
        aka_title m
    WHERE 
        m.title LIKE '%adventure%' -- Start with movies that have 'adventure' in the title
    
    UNION ALL
    
    SELECT 
        DISTINCT lm.linked_movie_id,
        l.title,
        l.production_year,
        rm.level + 1
    FROM 
        RelatedMovies rm
    JOIN 
        movie_link ml ON rm.movie_id = ml.movie_id
    JOIN 
        aka_title l ON ml.linked_movie_id = l.id
    WHERE 
        rm.level < 3 -- Limit depth of recursion
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN mi.info_type_id = 1 THEN NULLIF(CAST(mi.info AS NUMERIC), 0) END) AS average_info -- Example using info type to calculate average
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    RelatedMovies rm ON t.id = rm.movie_id -- Join with recursive CTE
WHERE 
    a.name IS NOT NULL
    AND (t.production_year BETWEEN 2000 AND 2020 OR t.title ILIKE '%festival%')
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 2 
ORDER BY 
    AVG(COALESCE(mi.info::numeric, 0)) DESC, 
    a.name ASC;
