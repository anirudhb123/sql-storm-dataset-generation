WITH MovieTitles AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(SUM(mk.id), 0) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
),
CastRoles AS (
    SELECT 
        ci.movie_id, 
        rt.role, 
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
RankedMovies AS (
    SELECT 
        mt.movie_id, 
        mt.title, 
        mt.production_year, 
        mt.keyword_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.keyword_count DESC) AS rank
    FROM 
        MovieTitles mt
    WHERE 
        mt.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    tm.title AS top_movie_title,
    tm.production_year AS year,
    COALESCE(cr.role, 'Unknown Role') AS cast_role,
    cr.role_count AS number_of_cast,
    COALESCE(cn.name, 'Studio Unknown') AS company_name
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.movie_id
LEFT JOIN 
    CastRoles cr ON tm.movie_id = cr.movie_id
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    (tm.production_year > 2000 OR cr.role IS NOT NULL)
    AND (imdb_index IS NOT NULL OR cr.role IS NULL)
ORDER BY 
    tm.production_year DESC, 
    mt.keyword_count DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

-- This query ranks movies based on keyword counts, selects the top movies,
-- joins with cast information, and includes company names while handling NULLs,
-- applying several SQL constructs like CTEs, window functions, and outer joins.
