WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ROW_NUMBER() OVER (PARTITION BY YEAR(m.production_year) ORDER BY m.production_year DESC) AS rank,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
RecentMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.rank, 
        rm.cast_count,
        CASE 
            WHEN rm.rank <= 5 THEN 'Top Recent'
            ELSE 'Other'
        END AS category
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
MoviesWithKeywords AS (
    SELECT 
        mv.movie_id,
        mv.title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mv.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        RecentMovies mv
    LEFT JOIN 
        movie_keyword mk ON mv.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        GROUP_CONCAT(DISTINCT r.role ORDER BY r.role SEPARATOR ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    m.title AS movie_title,
    NULLIF(m.cast_count, 0) AS total_cast,  -- NULL logic to handle zero case
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COALESCE(cr.roles, 'No Roles Assigned') AS cast_roles,
    m.category
FROM 
    RecentMovies m
LEFT JOIN 
    MoviesWithKeywords k ON m.movie_id = k.movie_id
LEFT JOIN 
    CastRoles cr ON m.movie_id = cr.movie_id
WHERE 
    m.cast_count >= 1 
    AND (k.keyword_rank IS NULL OR k.keyword_rank < 4)  -- (Potential outside range case)
ORDER BY 
    m.category, 
    m.title;
