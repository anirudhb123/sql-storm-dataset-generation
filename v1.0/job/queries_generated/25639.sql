WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.id) AS cast_count,
        AVG(CASE WHEN c.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.avg_roles,
        rm.actor_names,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.production_year,
        tm.cast_count,
        tm.avg_roles,
        tm.actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id, tm.movie_title, tm.production_year, tm.cast_count, tm.avg_roles, tm.actor_names
)
SELECT 
    mwk.movie_id,
    mwk.movie_title,
    mwk.production_year,
    mwk.cast_count,
    mwk.avg_roles,
    mwk.actor_names,
    mwk.keywords,
    CASE 
        WHEN mwk.cast_count > 10 THEN 'High'
        WHEN mwk.cast_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS cast_size_category
FROM 
    MoviesWithKeywords mwk
WHERE 
    mwk.keywords IS NOT NULL
ORDER BY 
    mwk.cast_count DESC,
    mwk.production_year DESC
LIMIT 10;
