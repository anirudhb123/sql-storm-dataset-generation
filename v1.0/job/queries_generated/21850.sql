WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        COUNT(cc.id) AS cast_count,
        COALESCE(MAX(cc.nr_order), 0) AS max_nr_order
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
    
    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        mt.title, 
        mt.production_year, 
        mh.cast_count, 
        mh.max_nr_order
    FROM 
        movie_link ml
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    INNER JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.cast_count,
    mh.max_nr_order,
    CASE 
        WHEN mh.max_nr_order IS NULL THEN 'No Cast'
        WHEN mh.max_nr_order > 5 THEN 'Large Cast'
        ELSE 'Small Cast' 
    END AS cast_size_category
FROM 
    MovieHierarchy mh
WHERE 
    mh.production_year >= 2000
ORDER BY 
    cast_size_category DESC, 
    mh.cast_count DESC;

This SQL query explores a recursive CTE (Common Table Expression) to create a movie hierarchy based on links between movies. It joins tables such as `aka_title`, `complete_cast`, and `movie_link`, aggregates cast counts, and categorizes the results into "No Cast", "Large Cast", and "Small Cast". It specifically filters for movies produced from the year 2000 onward and orders the results by the cast size category (in descending order) and number of cast members (in descending order).
