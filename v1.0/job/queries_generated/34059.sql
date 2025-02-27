WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        0 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        t2.id AS title_id,
        t2.title,
        t2.production_year,
        th.level + 1
    FROM 
        aka_title t2
    JOIN 
        TitleHierarchy th ON t2.episode_of_id = th.title_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT c.id) AS cast_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT ci.note) FILTER (WHERE ci.note IS NOT NULL) AS non_null_notes,
    AVG(CASE WHEN p.info IS NOT NULL THEN LENGTH(p.info) ELSE 0 END) AS avg_person_info_length,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS actor_movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    TitleHierarchy th ON th.title = m.title
WHERE 
    m.production_year > 2000
    AND (a.name IS NOT NULL OR a.name_pcode_cf IS NOT NULL)
GROUP BY 
    a.id, a.name, m.title, m.production_year
ORDER BY 
    actor_name ASC, production_year DESC;

### Explanation:
1. **Recursive CTE (TitleHierarchy)**: This constructs a hierarchy of titles allowing to find episodes linked to series.
2. **Main Query**: 
   - Joins `aka_name`, `cast_info`, and `aka_title` to correlate actors with movies.
   - Uses `LEFT JOIN` to include optional keyword information and person-specific info like notes.
   - Aggregates data such as counting distinct cast members, aggregating keywords, and calculating average length for non-null notes info.
   - Applies conditional aggregation to filter out NULLs in `notes`.
   - Uses `ROW_NUMBER()` window function to rank movies for each actor.
3. **WHERE Clause**: Filters movies released after 2000 and checks for non-null names.
4. **GROUP BY and ORDER BY**: Groups results by actor and title, sorted by actor name and production year.
