WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy h ON m.episode_of_id = h.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(c.name, 'Unknown') AS company_name,
    COUNT(DISTINCT ct.kind) AS company_types,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    STRING_AGG(DISTINCT p.name, ', ') AS actors,
    AVG(CASE 
        WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN CAST(mi.info AS FLOAT) 
        ELSE NULL 
    END) AS average_rating,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
FROM 
    MovieHierarchy m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
WHERE 
    m.production_year >= 2000
GROUP BY 
    m.title, m.production_year, c.name
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    m.production_year DESC, cast_count DESC;

The query does the following:
1. Uses a recursive Common Table Expression (CTE) `MovieHierarchy` to gather movie titles, production years, and their hierarchy in terms of episodes.
2. Joins the CTE with several tables to aggregate data about associated companies, cast, and ratings.
3. Calculates the count of distinct company types and cast members.
4. Uses a string aggregation to list out the names of the actors.
5. Computes the average movie rating while handling NULL values and using a subquery to find the appropriate rating type.
6. Ranks the films by production year and the number of cast members.
7. Filters the results to only include movies produced from 2000 onwards that have more than 2 cast members.
8. Orders the final results by `production_year` in descending order and `cast_count` in descending order as well.
