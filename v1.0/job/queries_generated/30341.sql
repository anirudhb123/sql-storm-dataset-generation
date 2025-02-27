WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        1 AS depth
    FROM 
        title t
    WHERE 
        t.season_nr IS NOT NULL  -- Start with titles that are episodes

    UNION ALL

    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        mh.depth + 1
    FROM 
        title t
    JOIN 
        movie_link ml ON t.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.title_id
)

SELECT 
    t.title AS episode_title,
    t.production_year AS episode_year,
    COALESCE(c.name, 'Unknown') AS cast_member,
    COUNT(DISTINCT mh.title_id) AS associated_movies,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE 
            WHEN m.production_year IS NOT NULL THEN m.production_year 
            ELSE NULL 
        END) AS avg_movie_year,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_order
FROM 
    title t
LEFT JOIN 
    cast_info c ON t.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    MovieHierarchy mh ON t.id = mh.title_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id 
WHERE 
    t.production_year >= 2000 
    AND (c.note IS NULL OR c.note NOT LIKE '%extra%')
GROUP BY 
    t.id, c.name
HAVING 
    COUNT(DISTINCT mh.title_id) > 0
ORDER BY 
    episode_year DESC, associated_movies DESC;

This query generates a performance benchmark involving:
- A recursive CTE (Common Table Expression) named `MovieHierarchy` to get episode titles and their linked movies.
- Various joins including left joins to combine data from related tables.
- Aggregate functions with conditions and window functions for ranking.
- Use of string aggregation to collect keywords.
- Complex predicates, including null checks and conditional expressions. 
- Data grouping and ordering to make results useful for performance insights.
