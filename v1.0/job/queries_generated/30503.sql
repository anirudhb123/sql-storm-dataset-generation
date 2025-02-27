WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        COALESCE(m.title, 'Unknown Title') AS title,
        1 AS level
    FROM
        title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Base case for hierarchy

    UNION ALL

    SELECT
        m.id AS movie_id,
        COALESCE(m.title, 'Unknown Title') AS title,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        title m ON ml.linked_movie_id = m.id
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    ak.name AS actor_name,
    mt.production_year,
    mh.title AS linked_movie_title,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    COUNT(DISTINCT kw.keyword) AS total_keywords,
    MAX(mi.info) AS latest_info,
    STRING_AGG(DISTINCT ci.note, ', ') AS roles_noted,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS movie_rank,
    CASE 
        WHEN MAX(mt.production_year) < 2000 THEN 'Classic'
        WHEN MAX(mt.production_year) BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    title mt ON at.movie_id = mt.id
LEFT JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_hierarchy mh ON mt.id = mh.movie_id
GROUP BY 
    ak.name, mt.production_year, mh.title
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5 OR COUNT(DISTINCT kw.keyword) > 3
ORDER BY 
    total_movies DESC, actor_name ASC;

This query constructs an extensive analysis of actors linked to movies, categorizing them by movie era and counting various movie metrics through a recursive CTE. It aggregates data using window functions and performs left joins to enrich the results with keywords associated with each movie. Additionally, it applies a case statement to classify movies based on release years, illustrating a multi-faceted approach to data retrieval.
