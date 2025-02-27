WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN cast_info ci ON ci.movie_id = mt.id
    GROUP BY mt.id, mt.title, mt.production_year
),
ActorNames AS (
    SELECT 
        an.person_id,
        STRING_AGG(an.name, ', ') AS actor_names
    FROM aka_name an
    INNER JOIN cast_info ci ON ci.person_id = an.person_id
    GROUP BY an.person_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
MovieStats AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ak.actor_names, 'Unknown Actors') AS actors,
        COALESCE(kc.keyword_count, 0) AS total_keywords
    FROM RankedMovies rm
    LEFT JOIN ActorNames ak ON ak.person_id = rm.movie_id
    LEFT JOIN KeywordCounts kc ON kc.movie_id = rm.movie_id
    WHERE rm.rank = 1
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.actors,
    REPLACE(REPLACE(ms.actors, ' ', ''), ',', '') AS actors_concat_no_spaces,
    CASE 
        WHEN ms.total_keywords > 5 THEN 'High' 
        WHEN ms.total_keywords BETWEEN 1 AND 5 THEN 'Medium' 
        ELSE 'Low' 
    END AS keyword_quality,
    CASE 
        WHEN ms.total_keywords IS NULL THEN 'No Keywords'
        WHEN ms.total_keywords > 0 THEN 'Contains Keywords'
        ELSE 'Keyword Count Unavailable'
    END AS keyword_annotation
FROM MovieStats ms
WHERE ms.title ILIKE '%a%' -- Filter for titles containing the letter 'a'
ORDER BY ms.production_year DESC, ms.total_keywords DESC
LIMIT 10;

-- Additional Statistics: Count rejection based on NULL logic in movie titles 
WITH NullRejections AS (
    SELECT 
        mv.title,
        COUNT(*) AS rejection_count
    FROM title mv
    WHERE mv.title IS NULL OR mv.title = ''
    GROUP BY mv.title
)
SELECT
    nr.title,
    nr.rejection_count,
    CASE
        WHEN nr.rejection_count > 0 THEN 'Rejected' 
        ELSE 'Accepted' 
    END AS status
FROM NullRejections nr;

This SQL query showcases a multitude of features including Common Table Expressions (CTEs), window functions for ranking, outer joins, string aggregation, and handling of NULL values. It emphasizes performance benchmarks by selecting the top-ranked movies per production year and providing detailed actor information alongside keyword counts. The query additionally Includes complex predicates and NULL logic with a further analysis on title rejections including a few bizarre outputs based on the filtering logic.
