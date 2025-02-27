WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assuming 1 represents a specific type of movie, e.g., "feature film"

    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        at.title, 
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 5 -- Limit the hierarchy to prevent infinite recursion
),
TopRatedMovies AS (
    SELECT 
        title.movie_id,
        title.title,
        COUNT(ct.id) AS cast_count,
        AVG(CASE WHEN pi.info_type_id = 1 THEN pi.info::numeric ELSE NULL END) AS avg_rating -- Assuming info_type_id = 1 represents ratings
    FROM 
        title
    LEFT JOIN 
        complete_cast cc ON title.id = cc.movie_id
    LEFT JOIN 
        cast_info ct ON cc.subject_id = ct.person_id
    LEFT JOIN 
        person_info pi ON ct.person_id = pi.person_id
    WHERE 
        title.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        title.movie_id, title.title
),
MoviesWithKeywords AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mt.title
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    tr.cast_count,
    tr.avg_rating,
    CASE 
        WHEN tr.avg_rating IS NULL THEN 'No Rating'
        WHEN tr.avg_rating > 8 THEN 'Highly Rated'
        WHEN tr.avg_rating BETWEEN 5 AND 8 THEN 'Moderately Rated'
        ELSE 'Poorly Rated'
    END AS rating_category,
    kw.keywords
FROM 
    MovieHierarchy mh
LEFT JOIN 
    TopRatedMovies tr ON mh.movie_id = tr.movie_id
LEFT JOIN 
    MoviesWithKeywords kw ON mh.movie_id = kw.movie_id
WHERE 
    mh.level = 1 -- Only top-level movies
ORDER BY 
    tr.avg_rating DESC NULLS LAST, 
    mh.movie_title;
This query performs the following actions:

1. **Recursive CTE `MovieHierarchy`**: Extracts a hierarchy of movies based on links to other movies, limiting the depth to avoid infinite loops.

2. **CTE `TopRatedMovies`**: Calculates the average rating and the count of cast members for movies produced between 2000 and 2023.

3. **CTE `MoviesWithKeywords`**: Aggregates distinct keywords for each movie.

4. **Main SELECT Statement**: Joins the three CTEs to get the final result, which includes movie titles, cast count, average rating, rating category with NULL handling, and keywords for top-level movies, ordering by rating and title. 

Each step cleverly utilizes SQL constructs like CTEs, outer joins, aggregates, and case expressions to provide a comprehensive view of the movies in the dataset.
