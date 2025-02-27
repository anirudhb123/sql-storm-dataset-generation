WITH MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        CASE 
            WHEN ls.role IS NOT NULL THEN ls.role 
            ELSE 'Not specified' 
        END AS role,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS cast_order
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN role_type ls ON c.role_id = ls.id
    WHERE m.production_year IS NOT NULL
),

AggregateMovieInfo AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword, ', ') AS keywords,
        STRING_AGG(role, ', ') AS roles,
        COUNT(DISTINCT cast_order) AS total_cast
    FROM MovieInfo
    GROUP BY movie_id
),

MaxCastMovies AS (
    SELECT 
        movie_id,
        total_cast,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM AggregateMovieInfo
    WHERE total_cast > 1
),

FinalOutput AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        a.keywords,
        a.roles,
        COALESCE(a.total_cast, 0) AS total_cast,
        COALESCE(m.production_year, 'Unknown Year') AS production_year,
        CASE 
            WHEN a.total_cast = (SELECT MAX(total_cast) FROM MaxCastMovies) THEN 'Top Cast Movie' 
            ELSE 'Regular Movie' 
        END AS movie_type
    FROM aka_title m
    LEFT JOIN AggregateMovieInfo a ON m.id = a.movie_id
)

SELECT 
    f.movie_id,
    f.title,
    f.keywords,
    f.roles,
    f.total_cast,
    f.production_year,
    f.movie_type
FROM FinalOutput f
WHERE f.total_cast IS NOT NULL 
ORDER BY f.production_year DESC, f.total_cast DESC
LIMIT 100;

