WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastStats AS (
    SELECT 
        ci.movie_id, 
        COUNT(ci.person_id) AS total_cast, 
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        mh.depth,
        cs.total_cast,
        cs.cast_names,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.id = mh.movie_id
    LEFT JOIN 
        CastStats cs ON t.id = cs.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id, 
            STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON t.id = mk.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.depth,
    md.total_cast,
    md.cast_names,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 1990 AND 2020
ORDER BY 
    md.depth DESC, 
    md.production_year DESC
LIMIT 50;

This SQL query constructs an elaborate report that includes:
- A recursive CTE `MovieHierarchy` to explore movie relationships.
- A `CastStats` CTE for aggregating cast information.
- Another CTE `MovieDetails` that consolidates movie titles, production years, and depths of the hierarchy along with cast details and associated keywords.
- Final selection with a filter on production years and ordered by depth and year.
