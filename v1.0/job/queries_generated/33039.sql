WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        linked_movie.linked_movie_id,
        linked_movie.title,
        mh.level + 1
    FROM 
        movie_link AS linked_movie
    JOIN 
        MovieHierarchy AS mh ON linked_movie.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS c ON m.id = c.movie_id
    GROUP BY 
        m.id
),
FilteredMovies AS (
    SELECT 
        rm.* 
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5 AND rm.movie_rank <= 10
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    f.title AS movie_title,
    f.production_year,
    f.cast_count,
    cs.company_count,
    cs.companies,
    mh.level
FROM 
    FilteredMovies f
LEFT JOIN 
    CompanyStats cs ON f.movie_id = cs.movie_id
LEFT JOIN 
    MovieHierarchy mh ON f.movie_id = mh.movie_id
WHERE 
    cs.company_count IS NOT NULL
    AND f.production_year IN (SELECT DISTINCT production_year FROM rankedmovies WHERE cast_count > 5)
ORDER BY 
    f.production_year DESC, 
    f.cast_count DESC;
