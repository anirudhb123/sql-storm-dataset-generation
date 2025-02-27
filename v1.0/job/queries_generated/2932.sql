WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
MovieRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, c.person_id, r.role
),
DetailedMovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COALESCE(c.name, 'Unknown Cast') AS cast_name,
        COALESCE(CNT.role_count, 0) AS role_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        MovieRoles CNT ON CNT.movie_id = m.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
),
FinalReport AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cast_name, ', ') AS cast_names,
        SUM(role_count) AS total_roles
    FROM 
        DetailedMovieInfo
    GROUP BY 
        title, production_year
)
SELECT 
    *,
    CASE 
        WHEN total_roles > 10 THEN 'Popular'
        WHEN total_roles > 0 THEN 'Moderate'
        ELSE 'Unpopular'
    END AS popularity
FROM 
    FinalReport
ORDER BY 
    production_year DESC, title ASC;
