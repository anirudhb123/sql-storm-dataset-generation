WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.imdb_index,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        linked_movie.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        m.imdb_index,
        mh.level + 1
    FROM 
        movie_link linked_movie
    JOIN 
        aka_title m ON linked_movie.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = linked_movie.movie_id
)
SELECT 
    COALESCE(cast_name.name, 'Unknown') AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MAX(mo.info) AS highest_rating,
    SUM(CASE 
            WHEN m.production_year < 2000 THEN 1 
            ELSE 0 
        END) AS pre_2000_count,
    COUNT(DISTINCT CASE 
        WHEN ci.note IS NULL THEN 0 
        ELSE ci.note 
    END) AS non_null_cast_notes,
    STRING_AGG(DISTINCT ci.note, ', ') AS all_cast_notes
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name cast_name ON ci.person_id = cast_name.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    movie_info mo ON mh.movie_id = mo.movie_id 
WHERE 
    mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    AND mh.level < 3
GROUP BY 
    cast_name.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mk.keyword) > 2
ORDER BY 
    pre_2000_count DESC, 
    highest_rating DESC NULLS LAST, 
    mh.production_year DESC;
