
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
        LISTAGG(an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actor_names
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
WHERE ms.title ILIKE '%a%' 
ORDER BY ms.production_year DESC, ms.total_keywords DESC
LIMIT 10;
