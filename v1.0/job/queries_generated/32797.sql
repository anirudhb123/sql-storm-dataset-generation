WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
FilmRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS male_actors,
        SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_actors
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        name p ON c.person_id = p.id
    GROUP BY 
        c.movie_id, r.role
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    fr.actor_count,
    fr.male_actors,
    fr.female_actors,
    COALESCE(mw.keywords, '{}') AS keywords,
    CASE 
        WHEN fr.actor_count > 10 THEN 'Ensemble Cast'
        WHEN fr.actor_count BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    MovieHierarchy mh
LEFT JOIN 
    FilmRoles fr ON mh.movie_id = fr.movie_id
LEFT JOIN 
    MoviesWithKeywords mw ON mh.movie_id = mw.movie_id
WHERE 
    mh.level = 0
ORDER BY 
    mh.production_year DESC, mh.title;

### Explanation:
1. **CTE Structure**:
   - `MovieHierarchy`: A recursive CTE that retrieves movies produced after 2000 and links them to any sequels/prequels.
   - `FilmRoles`: Aggregates data from `cast_info`, counting distinct actors and separating them by gender.
   - `MoviesWithKeywords`: Gathers keywords associated with each movie from `movie_keyword`.

2. **Main Query**:
   - Joins the CTEs and selects various aggregated information about the movies, including their titles, production years, actor statistics, and keywords.
   - The use of `COALESCE` ensures that movies without keywords will return an empty array instead of NULL.
   - A calculated column categorizes the size of the cast based on the number of actors involved.

3. **Ordering**: Results are ordered by production year and title.

This SQL statement showcases advanced constructs such as CTEs, aggregates, LEFT JOINs, and conditional logic while adhering to the structure of a richer movie database schema.
