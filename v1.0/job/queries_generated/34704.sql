WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        mc.linked_movie_id,
        mc.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link mc
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id
    JOIN 
        aka_title m ON mc.linked_movie_id = m.id
),
AvgRoleCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL AND cn.country_code <> ''
    GROUP BY 
        mc.movie_id
),
MoviesWithKeywords AS (
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
    mh.movie_title,
    mh.production_year,
    COALESCE(rc.role_count, 0) AS role_count,
    COALESCE(cc.company_count, 0) AS company_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    AvgRoleCount rc ON mh.movie_id = rc.movie_id
LEFT JOIN 
    CompanyMovies cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    MoviesWithKeywords mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.depth <= 3
ORDER BY 
    mh.production_year DESC, mh.movie_title;

This SQL query incorporates several advanced features including:

1. A **recursive CTE** (`MovieHierarchy`) to build a hierarchy of movies produced since 2000, exploring linked movies up to a depth of 3.
2. An **aggregate subquery** (`AvgRoleCount`) to count distinct roles (persons) for each movie.
3. Another **aggregate subquery** (`CompanyMovies`) to count distinct production companies associated with each movie, considering only companies with valid non-empty country codes.
4. A subquery for extracting keywords (`MoviesWithKeywords`) implemented with `STRING_AGG` to concatenate all distinct keywords related to each movie.
5. **Outer joins** to combine information from the various CTEs with handling for cases where there may be no associated roles, companies, or keywords, using `COALESCE` for NULL logic.
6. The final selection restricts results to movies within a certain hierarchical depth and sorts them by production year and title.
