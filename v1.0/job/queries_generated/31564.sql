WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 1 AS level
    FROM aka_title mt
    WHERE mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT mt.id AS movie_id, mt.title, mt.production_year, mh.level + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE mh.level < 5
),
AggregateData AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        COUNT(CASE WHEN ci.note IS NOT NULL THEN 1 END) AS cast_notes_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS year_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    WHERE t.production_year IS NOT NULL 
    GROUP BY c.id, a.name, t.title, t.production_year
),
YearlySummary AS (
    SELECT
        production_year,
        COUNT(DISTINCT movie_title) AS total_movies,
        SUM(keyword_count) AS total_keywords
    FROM AggregateData
    GROUP BY production_year
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ads.total_movies, 0) AS total_movies_in_year,
    COALESCE(ads.total_keywords, 0) AS total_keywords_in_year,
    ads.year_rank
FROM MovieHierarchy mh
LEFT JOIN YearlySummary ads ON mh.production_year = ads.production_year
ORDER BY mh.production_year DESC, mh.title;
This SQL query uses recursive Common Table Expressions (CTEs) to build a hierarchy of movies linked by `movie_link`, aggregates relevant data such as keywords and cast details, and provides a summary by production year while including join constructs and window functions for analytical capabilities.
