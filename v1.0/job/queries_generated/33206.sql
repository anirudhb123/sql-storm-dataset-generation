WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        m.imdb_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Assuming kind_id 1 represents 'feature film'
        
    UNION ALL
    
    SELECT 
        c.linked_movie_id AS movie_id, 
        m.title AS movie_title, 
        m.production_year, 
        m.imdb_id,
        mh.level + 1
    FROM 
        movie_link c
    JOIN 
        aka_title m ON c.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON c.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast,
    COALESCE(cn.name, 'No Company') AS company_name,
    COUNT(DISTINCT mw.keyword) AS keyword_count,
    AVG(CASE WHEN mpi.info_type_id = 1 THEN NULLIF(mpi.info::numeric, 0) ELSE NULL END) AS average_rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
LEFT JOIN 
    movie_info mpi ON mh.movie_id = mpi.movie_id
WHERE 
    mh.production_year >= 2000 
    AND (cn.country_code IS NULL OR cn.country_code != 'US')
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, cn.name
HAVING 
    COUNT(DISTINCT a.person_id) > 5  -- At least 6 cast members
ORDER BY 
    mh.production_year DESC, 
    keyword_count DESC;

This SQL query accomplishes the following:

1. It uses a recursive CTE (`MovieHierarchy`) to retrieve a hierarchy of movies linked through a `movie_link` table.
2. It pulls in detailed casting information via the `complete_cast`, `cast_info`, `aka_name`, and `role_type` tables.
3. It includes company details through outer joins with `movie_companies` and `company_name`, ensuring to handle NULL values in company information.
4. It aggregates keyword data by counting distinct keywords for each movie via `movie_keyword`.
5. It calculates an average rating conditionally based on `movie_info`, using `NULLIF` to avoid division errors when the rating might be zero.
6. It filters for movies produced after the year 2000, explicitly excluding those associated with U.S. companies, while requiring at least six unique cast members.
7. The final result is ordered by the production year (newest first) and the number of keywords (most to least).
