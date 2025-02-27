WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        a.name AS actor_name,
        1 AS depth
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL
    
    SELECT 
        ca.id AS cast_id,
        ca.person_id,
        ca.movie_id,
        a.name AS actor_name,
        ah.depth + 1
    FROM 
        cast_info ca
    JOIN 
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        ca.id <> ah.cast_id
),
MovieDetails AS (
    SELECT
        at.id AS title_id,
        at.title,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COALESCE(SUM(mk.id), 0) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    GROUP BY 
        at.id, at.title
),
AggregatedMovies AS (
    SELECT 
        title_id,
        title,
        actors,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    am.title_id,
    am.title,
    am.actors,
    am.keyword_count,
    CASE 
        WHEN am.keyword_count > 5 THEN 'High'
        WHEN am.keyword_count BETWEEN 3 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_category,
    ah.depth AS actor_depth
FROM 
    AggregatedMovies am
LEFT JOIN 
    ActorHierarchy ah ON am.title_id = ah.movie_id
WHERE 
    am.rank <= 10
ORDER BY 
    am.keyword_count DESC, am.title ASC;
