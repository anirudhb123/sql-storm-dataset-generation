
WITH RecursiveCTE AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(CASE WHEN a.name IS NOT NULL THEN a.name ELSE 'Unknown Actor' END) AS sample_actor_name
    FROM cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY c.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS all_keywords
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title
),
IncompleteMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ci.actor_count, 0) AS actor_count,
        COALESCE(mk.all_keywords, 'No Keywords') AS keywords
    FROM title m
    LEFT JOIN RecursiveCTE ci ON m.id = ci.movie_id
    LEFT JOIN MoviesWithKeywords mk ON m.id = mk.movie_id
),
FinalSelection AS (
    SELECT 
        movie_id,
        title,
        actor_count,
        keywords,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, title) AS rn
    FROM IncompleteMovieInfo
    WHERE actor_count > 0
      AND (keywords IS NOT NULL AND keywords <> 'No Keywords')
)

SELECT 
    movie_id,
    title,
    actor_count,
    keywords,
    CASE 
        WHEN actor_count > 10 THEN 'Highly Casted'
        WHEN actor_count BETWEEN 5 AND 10 THEN 'Moderately Casted'
        ELSE 'Poorly Casted'
    END AS cast_quality,
    CONCAT('Keywords: ', keywords) AS detailed_keywords
FROM FinalSelection
WHERE rn <= 50
ORDER BY actor_count DESC;
