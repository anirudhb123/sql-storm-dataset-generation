WITH RecursiveMovieHierarchy AS (
    -- CTE to establish a recursive relationship to fetch all linked movies
    SELECT 
        m.id AS movie_id, 
        COALESCE(m.title, 'Untitled') AS title,
        1 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL

    SELECT 
        ml.linked_movie_id, 
        COALESCE(aka.title, 'Untitled') AS title,
        r.level + 1 
    FROM 
        movie_link AS ml
    JOIN 
        RecursiveMovieHierarchy AS r ON r.movie_id = ml.movie_id
    LEFT JOIN 
        aka_title AS aka ON ml.linked_movie_id = aka.id 
    WHERE 
        aka.production_year IS NOT NULL
),

RankedMovieInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY m.level DESC) AS rank
    FROM 
        RecursiveMovieHierarchy AS m
),

FirstMovieYear AS (
    SELECT 
        m.movie_id,
        MIN(m.production_year) AS first_year
    FROM 
        aka_title AS m
    GROUP BY 
        m.movie_id
)

SELECT 
    r.movie_id,
    r.title,
    COALESCE(f.first_year, 'Unknown Year') AS debut_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    ARRAY_AGG(DISTINCT kn.keyword) AS keywords,
    CASE 
        WHEN COUNT(DISTINCT ci.person_id) IS NULL THEN 'No Cast Available'
        ELSE 'Has Cast'
    END AS cast_status,
    MAX(mi.info) FILTER (WHERE it.info = 'Rating') AS highest_rating
FROM 
    RankedMovieInfo AS r
LEFT JOIN 
    cast_info AS ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword AS mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS kn ON mk.keyword_id = kn.id
LEFT JOIN 
    FirstMovieYear AS f ON r.movie_id = f.movie_id
LEFT JOIN 
    movie_info AS mi ON r.movie_id = mi.movie_id
LEFT JOIN 
    info_type AS it ON mi.info_type_id = it.id
WHERE 
    r.rank = 1 AND 
    (f.first_year IS NOT NULL OR r.title LIKE '%Legend%')
GROUP BY 
    r.movie_id, r.title, f.first_year
ORDER BY 
    debut_year DESC,
    actor_count DESC
LIMIT 100;

This query includes various advanced SQL constructs:
- **Common Table Expressions (CTEs)** used for recursive queries and ranking.
- **Window functions** for ranking movies.
- Use of **NULL logic** to handle missing cast members and production years.
- **Outer joins** to include movies even if they have no keywords or actors.
- **Set operations** to aggregate keywords for movies.
- **Case expressions** for conditional output based on cast availability.
- Filtered aggregations for getting specific movie information.
- A combined selection of fascinating metadata about movies and their relationships.
