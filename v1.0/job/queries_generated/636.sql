WITH RankedActors AS (
    SELECT 
        ak.name AS actor_name, 
        COUNT(ci.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
), MoviesWithKeywords AS (
    SELECT 
        mt.title,
        mk.keyword,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.title ORDER BY mk.keyword) AS keyword_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id 
    WHERE 
        mt.production_year IS NOT NULL
), PopularMovies AS (
    SELECT 
        mw.keyword, 
        COUNT(mw.title) AS popular_count
    FROM 
        MoviesWithKeywords mw
    GROUP BY 
        mw.keyword
    HAVING 
        COUNT(mw.title) > 10
)
SELECT 
    ra.actor_name, 
    pm.keyword, 
    pm.popular_count, 
    COALESCE(SUM(ci.nr_order), 0) AS total_order
FROM 
    RankedActors ra
LEFT JOIN 
    cast_info ci ON ra.actor_name = (SELECT ak.name FROM aka_name ak WHERE ak.person_id = ci.person_id)
JOIN 
    PopularMovies pm ON pm.keyword IN (
        SELECT DISTINCT mk.keyword 
        FROM movie_keyword mk 
        JOIN aka_title mt ON mk.movie_id = mt.id 
        WHERE mt.production_year = (SELECT MAX(mt.production_year) FROM aka_title mt)
    )
GROUP BY 
    ra.actor_name, pm.keyword, pm.popular_count
ORDER BY 
    ra.actor_rank, pm.popular_count DESC;
