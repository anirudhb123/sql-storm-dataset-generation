WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        1 AS depth
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    WHERE an.name LIKE '%John%'
    
    UNION ALL
    
    SELECT 
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        ah.depth + 1
    FROM cast_info ci
    JOIN ActorHierarchy ah ON ci.movie_id IN (
        SELECT mk.movie_id
        FROM movie_keyword mk
        JOIN movie_keyword mk2 ON mk.keyword_id = mk2.keyword_id
        WHERE mk2.movie_id = ah.movie_id
    )
    WHERE ci.movie_id IS NOT NULL
), RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.id) DESC) AS rank
    FROM title t
    JOIN cast_info ci ON ci.movie_id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.title, t.production_year
), LatestMovies AS (
    SELECT 
        title,
        production_year
    FROM RankedMovies
    WHERE rank <= 5
)
SELECT 
    ah.depth,
    an.name AS actor_name,
    lm.title AS movie_title,
    lm.production_year,
    COALESCE(mci.note, 'No note available') AS company_note,
    COUNT(DISTINCT mv.id) AS linked_movies_count,
    SUM(CASE WHEN km.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count
FROM ActorHierarchy ah
JOIN aka_name an ON ah.person_id = an.person_id
JOIN latestMovies lm ON ah.movie_id = lm.movie_id
LEFT JOIN movie_companies mc ON mc.movie_id = ah.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN movie_link mv ON mv.movie_id = ah.movie_id
LEFT JOIN movie_keyword mk ON mk.movie_id = ah.movie_id
LEFT JOIN keyword km ON mk.keyword_id = km.id
LEFT JOIN movie_info mi ON mi.movie_id = ah.movie_id
LEFT JOIN movie_info_idx mii ON mii.movie_id = ah.movie_id
WHERE lm.production_year > 2000
GROUP BY ah.depth, an.name, lm.title, lm.production_year, mci.note
ORDER BY lm.production_year DESC, COUNT(DISTINCT ci.id) DESC;
