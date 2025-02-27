WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS level,
        CAST(t.title AS VARCHAR(255)) AS path
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    
    UNION ALL

    SELECT 
        mv.id,
        mh.title,
        mv.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || mv.title AS VARCHAR(255))
    FROM 
        complete_cast cc
    JOIN 
        movie_hierarchy mh ON cc.movie_id = mh.movie_id
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    JOIN 
        aka_title mv ON ci.movie_id = mv.id
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'Director')
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT cc.person_id) AS unique_actors,
    AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS average_cast_notes,
    STRING_AGG(DISTINCT kc.keyword, ', ') FILTER (WHERE kc.keyword IS NOT NULL) AS keywords,
    MAX(mk.created_at) AS last_keyword_entry
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    aka_name an ON mh.movie_id = an.id
WHERE 
    mh.level <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
ORDER BY 
    unique_actors DESC, production_year DESC;

This query does the following:
- Defines a recursive CTE (`movie_hierarchy`) that builds a hierarchy of movies produced in the USA, starting from directors and descending through their respective movie titles.
- Joins movie details with casting information and keywords.
- For each movie, it calculates:
  - Unique actors.
  - Average presence of notes in the cast information.
  - A concatenated string of unique keywords related to the movie.
  - The last time a keyword was entered.
- Filters for movies within a certain hierarchy level and outputs the results ordered by the number of unique actors and the production year.
