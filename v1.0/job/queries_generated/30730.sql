WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM 
        MovieHierarchy mh
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.name, 'Unknown') AS actor_name,
        array_agg(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ac ON cc.subject_id = ac.person_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.rank <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ac.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_name,
    md.keywords,
    md.company_count,
    CASE 
        WHEN md.company_count > 5 THEN 'High Production'
        WHEN md.company_count BETWEEN 3 AND 5 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_category
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.title;

This SQL query showcases a complex selection on the `aka_title` table and its relationships to various other tables. 

- **Recursive CTE**: The `MovieHierarchy` CTE establishes a recursive relationship to find linked movies, capturing levels of linkage.
- **Window Functions**: The `ROW_NUMBER()` function within `RankedMovies` ranks movies for each production year, allowing filtering to get top entries.
- **Outer Joins**: The use of `LEFT JOIN` ensures that even movies without certain attributes (like associated actors or companies) are included.
- **Aggregation**: Grouping operations such as `array_agg` to collect keywords and `COUNT` for the number of companies contribute to detailed movie insights.
- **Conditional Logic**: A `CASE` statement provides categorization of movies based on their production company count.
- **Organization**: The final output is organized by production year and title, contributing to a clear presentation of the result set.
