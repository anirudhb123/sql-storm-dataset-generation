WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND length(an.name) > 5  -- Filter names with more than 5 characters

    UNION ALL

    SELECT 
        mh.movie_id,
        cm.title,
        cm.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title cm ON ml.linked_movie_id = cm.id
    WHERE 
        cm.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(ci.person_id) AS total_cast_members,
    ARRAY_AGG(DISTINCT an.name) AS cast_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY 
    mh.production_year DESC, mh.level ASC;

This SQL query uses a recursive Common Table Expression (CTE) called `MovieHierarchy` to explore relationships between movies and their sequels or related films via the `movie_link` table. It starts by selecting movies alongside their titles and production years, filtering for movies with a specific 'kind'.

The query captures multiple levels of movie relationships, counts the total number of cast members for each movie, and aggregates the distinct names of these cast members. Finally, results are ordered by production year in descending order while ensuring the hierarchical levels are displayed in ascending order.
