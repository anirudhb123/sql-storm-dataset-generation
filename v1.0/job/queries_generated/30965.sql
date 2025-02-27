WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS TEXT) AS parent_movie_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming '1' refers to movies within your schema

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        a.title,
        a.production_year,
        mh.title AS parent_movie_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
)

SELECT 
    a.name AS actor_name,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mci.movie_id) AS total_movies,
    AVG(myranks.rank) AS average_rank,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(GROUP_CONCAT(DISTINCT ci.note), 'No notes available') AS notes
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY info) AS rank
     FROM 
         movie_info
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') -- Change 'Rating' to any relevant info_type used
    ) myranks ON mh.movie_id = myranks.movie_id
GROUP BY 
    a.name, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT mci.movie_id) > 5 
ORDER BY 
    average_rank DESC, 
    total_movies DESC
LIMIT 10;
