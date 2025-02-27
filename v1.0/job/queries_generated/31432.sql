WITH RECURSIVE ActorHierarchy AS (
    SELECT c.person_id, c.movie_id, a.name, 1 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.movie_id IN (
        SELECT movie_id
        FROM movie_info
        WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
        AND info LIKE '%adventure%'
    )
    UNION ALL
    SELECT ch.person_id, ch.movie_id, a.name, depth + 1
    FROM ActorHierarchy ch
    JOIN cast_info c ON ch.movie_id = c.movie_id
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE ch.depth < 3
),
MovieKeywordCounts AS (
    SELECT m.movie_id, COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN aka_title m ON mk.movie_id = m.movie_id
    GROUP BY m.movie_id
),
InfluentialMovies AS (
    SELECT m.title, m.production_year, ak.name, mk.keyword_count
    FROM aka_title m
    JOIN MovieKeywordCounts mk ON m.id = mk.movie_id
    JOIN ActorHierarchy ah ON m.id = ah.movie_id
    JOIN aka_name ak ON ah.person_id = ak.person_id
    WHERE mk.keyword_count >= 5
    ORDER BY mk.keyword_count DESC, m.production_year DESC
    LIMIT 10
)
SELECT DISTINCT im.title, im.production_year, im.name,
       (CASE 
            WHEN im.production_year < 2000 THEN 'Classic'
            WHEN im.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END) AS era,
       COUNT(c.movie_id) OVER (PARTITION BY im.name) AS movie_count
FROM InfluentialMovies im
LEFT JOIN complete_cast c ON im.movie_id = c.movie_id
WHERE im.title IS NOT NULL
AND im.name IS NOT NULL
ORDER BY movie_count DESC;
