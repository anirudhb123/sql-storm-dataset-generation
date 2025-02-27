WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id, 
        title, 
        production_year,
        0 AS level
    FROM 
        aka_title
    WHERE 
        episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        at.id AS movie_id, 
        at.title, 
        at.production_year,
        mh.level + 1
    FROM 
        aka_title AS at
    INNER JOIN 
        MovieHierarchy AS mh ON at.episode_of_id = mh.movie_id
),
FrequentActors AS (
    SELECT 
        ca.person_id,
        COUNT(*) AS movie_count
    FROM 
        cast_info AS ca
    JOIN 
        MovieHierarchy AS mh ON ca.movie_id = mh.movie_id
    GROUP BY 
        ca.person_id
    HAVING 
        COUNT(*) > 1
),
ActorInfo AS (
    SELECT 
        na.name AS actor_name, 
        fa.movie_count
    FROM 
        FrequentActors AS fa
    JOIN 
        aka_name AS na ON fa.person_id = na.person_id
),
TopMovies AS (
    SELECT 
        mh.title, 
        mh.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        cast_info AS ca ON mh.movie_id = ca.movie_id
    GROUP BY 
        mh.movie_id
    HAVING 
        COUNT(DISTINCT ca.person_id) >= 5
),
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    ki.keywords,
    ai.actor_name,
    ai.movie_count,
    ROW_NUMBER() OVER (PARTITION BY tm.production_year ORDER BY tm.actor_count DESC) AS rank_within_year
FROM 
    TopMovies AS tm
LEFT JOIN 
    KeywordMovies AS ki ON tm.movie_id = ki.movie_id
LEFT JOIN 
    ActorInfo AS ai ON ai.movie_count = tm.actor_count
WHERE 
    tm.production_year >= 2000 AND 
    (ai.actor_name IS NOT NULL OR ki.keywords IS NOT NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
