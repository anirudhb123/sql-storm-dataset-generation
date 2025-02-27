WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
keywords_list AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    COALESCE(kl.keywords, 'No Keywords') AS keywords,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    keywords_list kl ON mh.movie_id = kl.movie_id
WHERE 
    mh.production_year >= 2000  -- Filter on production year
ORDER BY 
    mh.production_year DESC, mh.title
LIMIT 100;

This SQL query does the following:

1. **Recursive CTE (`movie_hierarchy`)**: Establishes a movie hierarchy where it pulls movies and their linked relationships, progressing through linked movies (i.e. sequels, prequels).
   
2. **CTE for Cast Details (`cast_details`)**: Aggregates cast information per movie, counting distinct cast members and concatenating their names.

3. **CTE for Keywords List (`keywords_list`)**: Gathers keywords associated with each movie, joining through the `movie_keyword` table.

4. **Final Selection**: Joins the recursive movie hierarchy with the prepared `cast_details` and `keywords_list` CTEs to retrieve a comprehensive view of each movie from the year 2000 onwards, including cast information and keywords.

5. **ORDER BY & LIMIT**: Sorts the results by the production year (latest first) and movie title, limiting the output to 100 records. 

This query provides a complex performance benchmark and showcases various SQL constructs while utilizing the specified schema.
