WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        FALSE AS is_root
    FROM 
        aka_title m
    WHERE 
        m.kind_id = 1  -- Assume kind_id=1 designates a specific category, e.g., 'movie'
    
    UNION ALL
    
    SELECT 
        mc.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        TRUE AS is_root
    FROM 
        movie_link mc
    JOIN 
        aka_title at ON mc.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mc.movie_id = mh.movie_id
    WHERE 
        mh.is_root = FALSE
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mk.keywords,
        mc.company_name,
        mc.company_type,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC) AS movie_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieKeywords mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanyInfo mc ON mh.movie_id = mc.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(r.keywords, 'No Keywords') AS keywords,
    COALESCE(r.company_name, 'Unknown Company') AS company_name,
    r.company_type,
    r.movie_rank
FROM 
    RankedMovies r
WHERE 
    r.movie_rank <= 10  -- Choose top 10 movies per year based on rank
ORDER BY 
    r.production_year DESC, r.movie_rank;

This SQL query includes:
- A recursive CTE (`MovieHierarchy`) to build a tree of movies linked to each other.
- A CTE (`MovieKeywords`) for aggregating keywords associated with each movie.
- Another CTE (`MovieCompanyInfo`) to gather companies associated with movies.
- A ranked list of movies by using the `ROW_NUMBER()` window function to partition by the year.
- Use of outer joins to ensure all movies are included even if they lack keywords or company data.
- Handling of NULL values with `COALESCE` to provide default text when data is absent. 
- It selects the top 10 ranked movies for each production year, ordered by the year and rank.
