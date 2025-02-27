WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(SUM(CASE WHEN c.nr_order = 1 THEN 1 ELSE 0 END), 0) AS primary_cast_count,
        0 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year

    UNION ALL 

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        COALESCE(SUM(CASE WHEN ci.nr_order = 1 THEN 1 ELSE 0 END), 0) AS primary_cast_count,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        complete_cast cc ON ml.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    GROUP BY 
        ml.linked_movie_id, at.title, at.production_year, mh.level 
),

TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.primary_cast_count,
        DENSE_RANK() OVER (ORDER BY mh.primary_cast_count DESC) AS rank
    FROM 
        MovieHierarchy mh
    WHERE 
        mh.level = 0
)

SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.primary_cast_count,
    CASE 
        WHEN tm.rank <= 10 THEN 'Top 10'
        WHEN tm.rank <= 20 THEN 'Top 20'
        ELSE 'Other'
    END AS category,
    ARRAY(
        SELECT a.name
        FROM aka_name a
        JOIN cast_info ci ON a.person_id = ci.person_id
        WHERE ci.movie_id = tm.movie_id
    ) AS cast_names
FROM 
    TopMovies tm
WHERE 
    tm.production_year > (SELECT AVG(production_year) FROM aka_title)
ORDER BY 
    tm.rank
LIMIT 50;

This SQL query contains a Common Table Expression (CTE) `MovieHierarchy` that recursively builds a hierarchy of movies linked to others, counting primary casts. It also defines another CTE `TopMovies` to rank these movies based on cast count. The final selection queries against this ranked CTE, categorizing results while fetching arrays of actor names for each movie. It uses outer joins, correlated subqueries, window functions, and includes NULL logic for safe calculations throughout.
