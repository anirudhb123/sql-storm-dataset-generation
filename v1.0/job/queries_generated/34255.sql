WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CAST(NULL AS text) AS parent_title
    FROM 
        title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        m.title AS parent_title
    FROM 
        title e
    JOIN 
        MovieHierarchy m ON e.episode_of_id = m.movie_id
),
DetailedCastInfo AS (
    SELECT 
        c.movie_id,
        p.name AS person_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
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
    mh.parent_title,
    dci.person_name,
    dci.role_name,
    dci.role_order,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category
FROM 
    MovieHierarchy mh
LEFT JOIN 
    DetailedCastInfo dci ON mh.movie_id = dci.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.production_year DESC, mh.movie_id, dci.role_order;

### Explanation of the Query:

1. **Recursive CTE (MovieHierarchy)**: This CTE gathers all movies and their corresponding episodes. The initial query selects top-level movies (those without a parent), while the recursive part selects episodes of those movies.

2. **DetailedCastInfo CTE**: This collects detailed information on the cast for each movie, including each person's name and their role. It also assigns a `role_order` for sorting purposes.

3. **MovieKeywords CTE**: This aggregates keywords associated with each movie into a single string, separated by commas.

4. **Main Query**: The main SELECT statement retrieves details from the MovieHierarchy, along with cast information and keywords. It categorizes the movies into 'Classic', 'Modern', or 'Recent' based on the production year. 

5. **JOINS**: The query uses left joins to ensure that all movies are returned, even if they do not have associated cast or keywords.

6. **Ordering**: Finally, results are ordered by the production year (descending) followed by movie ID and their role order. 

This SQL query showcases multiple advanced SQL features, including recursive CTEs, window functions, aggregate functions, and various types of joins, providing a comprehensive view of the movie data for performance benchmarking.
