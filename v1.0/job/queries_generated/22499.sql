WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS hierarchy_path
    FROM 
        aka_title mt
    WHERE 
        mt.season_nr IS NULL
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1,
        CAST(mh.hierarchy_path || ' -> ' || m.title AS VARCHAR(255)) AS hierarchy_path
    FROM 
        aka_title m
    INNER JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)
SELECT 
    COALESCE(an.name, 'Unknown Actor') AS actor_name,
    at.title AS movie_title,
    at.production_year,
    CASE 
        WHEN at.production_year IS NULL THEN 'Year Unknown' 
        ELSE 'Year ' || at.production_year::TEXT 
    END AS year_statement,
    COUNT(DISTINCT mc.company_id) AS company_count,
    ARRAY_AGG(DISTINCT kw.keyword) FILTER (WHERE kw.keyword IS NOT NULL) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY an.id ORDER BY at.production_year DESC) AS actor_movie_rank,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
    STRING_AGG(DISTINCT ci.note, '; ') AS all_notes
FROM 
    aka_name an 
LEFT JOIN 
    cast_info ci ON an.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id 
WHERE 
    an.name IS NOT NULL
    AND NOT (at.title IS NULL OR at.title = '')
GROUP BY 
    an.id, at.title, at.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1 
    OR SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    year_statement DESC, actor_name
LIMIT 100;

-- Optional additional logic for exploring obscure semantic corner cases
SELECT 
    mh.hierarchy_path,
    COUNT(DISTINCT ci.movie_id) AS total_movies_in_hierarchy,
    MIN(at.production_year) AS earliest_year,
    MAX(at.production_year) AS latest_year
FROM 
    MovieHierarchy mh
JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
JOIN 
    aka_title at ON ci.movie_id = at.id
GROUP BY 
    mh.hierarchy_path
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    earliest_year DESC;
