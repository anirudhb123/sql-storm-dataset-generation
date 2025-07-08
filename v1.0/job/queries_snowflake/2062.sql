WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
CompleteMovieData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        COALESCE(mr.role, 'Unknown') AS role,
        COALESCE(mr.role_count, 0) AS role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywordCounts mkc ON rm.movie_id = mkc.movie_id
    LEFT JOIN 
        (SELECT movie_id, role, role_count FROM MovieRoles) mr ON rm.movie_id = mr.movie_id
)
SELECT 
    cmd.movie_id,
    cmd.title,
    cmd.production_year,
    cmd.keyword_count,
    cmd.role,
    cmd.role_count
FROM 
    CompleteMovieData cmd
WHERE 
    (cmd.production_year >= 2000 AND cmd.keyword_count > 5) 
    OR (cmd.role_count > 2 AND cmd.role != 'Unknown')
ORDER BY 
    cmd.production_year DESC, cmd.keyword_count DESC
LIMIT 50;
