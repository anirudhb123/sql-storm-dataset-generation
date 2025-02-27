WITH RankedActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        mt.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.movie_id, mt.title
),
PopularMovies AS (
    SELECT 
        mc.movie_id,
        m.title,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.movie_id
    JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    GROUP BY 
        mc.movie_id, m.title
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
)
SELECT 
    ra.name AS actor_name,
    mw.title AS movie_title,
    mw.keywords AS movie_keywords,
    pm.actor_count AS co_actor_count
FROM 
    RankedActors ra
LEFT JOIN 
    cast_info ci ON ra.person_id = ci.person_id
LEFT JOIN 
    MoviesWithKeywords mw ON ci.movie_id = mw.movie_id
LEFT JOIN 
    PopularMovies pm ON mw.movie_id = pm.movie_id
WHERE 
    ra.actor_rank <= 10 
    AND mw.keywords IS NOT NULL
ORDER BY 
    ra.movie_count DESC, pm.actor_count DESC;
