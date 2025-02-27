
WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(MAX(c.nr_order), 0) AS max_cast_order
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),

CastRoleInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS unique_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id 
),

MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(c.unique_actors, 0) AS actor_count,
    m.keywords,
    r.max_cast_order,
    CASE 
        WHEN COALESCE(c.unique_actors, 0) > 0 THEN 'Yes'
        ELSE 'No'
    END AS has_actors,
    (SELECT AVG(cast_count) 
     FROM (SELECT COUNT(*) AS cast_count FROM cast_info GROUP BY movie_id) AS subquery) AS avg_cast_per_movie,
    CASE 
        WHEN r.max_cast_order IS NULL THEN 'No Cast Info Available'
        WHEN r.max_cast_order < 3 THEN 'Limited Cast'
        ELSE 'Full Cast'
    END AS cast_quality
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    CastRoleInfo c ON r.movie_id = c.movie_id
LEFT JOIN 
    MoviesWithKeywords m ON r.movie_id = m.movie_id
ORDER BY 
    r.production_year DESC, 
    actor_count DESC,
    r.title;
