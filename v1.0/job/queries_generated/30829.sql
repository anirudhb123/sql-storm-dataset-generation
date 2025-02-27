WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ch.name AS character_name,
    p_info.info AS person_info,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT c_info.movie_id) AS total_movies,
    STRING_AGG(DISTINCT c_info.note, ', ') AS notes,
    ROW_NUMBER() OVER (PARTITION BY ch.name ORDER BY mh.production_year DESC) AS movie_rank,
    CASE 
        WHEN mh.production_year IS NULL THEN 'Year Not Available'
        ELSE mh.production_year::text
    END AS year_available,
    COALESCE(c_info.nr_order, 0) AS order_number
FROM 
    char_name ch
JOIN 
    cast_info c_info ON ch.imdb_id = c_info.person_id
LEFT JOIN 
    MovieHierarchy mh ON c_info.movie_id = mh.movie_id
LEFT JOIN 
    person_info p_info ON c_info.person_id = p_info.person_id 
                         AND p_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    (mh.production_year >= 2000 OR mh.production_year IS NULL)
    AND (c_info.note IS NOT NULL OR c_info.note IS NULL)
GROUP BY 
    ch.name, p_info.info, mh.title, mh.production_year, c_info.nr_order
ORDER BY 
    character_name, movie_rank;
