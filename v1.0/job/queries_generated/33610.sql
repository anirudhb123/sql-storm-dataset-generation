WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5
),
ActorStats AS (
    SELECT 
        ka.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(mt.production_year) AS avg_production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    GROUP BY 
        ka.person_id, a.name
),
TitleKeywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id
),
ActorTitles AS (
    SELECT 
        ka.person_id,
        ka.name AS actor_name,
        mt.title,
        mt.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    WHERE 
        mt.production_year BETWEEN 2010 AND 2023
),
FinalResults AS (
    SELECT 
        a.actor_name,
        COUNT(DISTINCT a.movie_count) AS total_movies,
        MIN(a.avg_production_year) AS first_movie_year,
        MAX(kw.keywords) AS keywords
    FROM 
        ActorStats a
    LEFT JOIN 
        TitleKeywords kw ON kw.movie_id IN (SELECT DISTINCT movie_id FROM ActorTitles WHERE actor_name = a.actor_name)
    GROUP BY 
        a.actor_name
)
SELECT 
    fr.actor_name,
    fr.total_movies,
    fr.first_movie_year,
    fr.keywords
FROM 
    FinalResults fr
WHERE 
    fr.total_movies > 2
ORDER BY 
    fr.total_movies DESC, 
    fr.first_movie_year ASC;
