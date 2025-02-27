WITH RECURSIVE MovieHierarchy AS (
    -- Recursive CTE to build a hierarchy of movies starting from a specific movie ID (e.g., 1).
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.id = 1

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mk.keyword AS MovieKeyword,
    at.title AS MovieTitle,
    at.production_year,
    COUNT(DISTINCT ca.person_id) AS CastCount,
    MAX(CASE WHEN ci.note IS NULL THEN ‘N/A’ ELSE ci.note END) AS MainRole,
    STRING_AGG(DISTINCT ak.name, ', ') AS AliasNames,
    ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS YearRank
FROM 
    aka_title at 
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.id
LEFT JOIN 
    aka_name ak ON ca.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    (
        SELECT 
            DISTINCT movie_id,
            STRING_AGG(DISTINCT title ORDER BY title) AS RelatedTitles
        FROM 
            movie_link ml
        WHERE 
            ml.link_type_id IS NOT NULL
        GROUP BY
            movie_id
    ) AS rt ON at.id = rt.movie_id
WHERE 
    at.production_year IS NOT NULL
GROUP BY 
    mk.keyword, at.title, at.production_year
ORDER BY 
    at.production_year DESC, CastCount DESC;

### Query Breakdown
1. **Recursive CTE (MovieHierarchy)**: This builds a hierarchy of movies starting from a specific movie ID, enabling an analysis of linked movies.
2. **SELECT Statement**: Gathers keywords, movie titles, production years, cast counts, notes, alias names, and assigns a year rank.
3. **LEFT JOINs**: Integrates various tables such as aka_title, movie_keyword, complete_cast, and aka_name to fetch comprehensive movie details.
4. **MAX CASE Expression**: Handles NULL values for specific notes, providing a default response.
5. **STRING_AGG**: Aggregates alias names into a single string for easy reading.
6. **ROW_NUMBER() Window Function**: Ranks movies by production year for analysis.
7. **WHERE Clause**: Filters out rows where production year is NULL.
8. **ORDER BY**: Sorts results to present the most recent movies with the highest cast counts.
