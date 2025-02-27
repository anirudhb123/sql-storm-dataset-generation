WITH RECURSIVE MovieHierarchy AS (
    -- CTE to find all related movies by episode_of_id recursively
    SELECT id AS movie_id, title, season_nr, episode_nr
    FROM aka_title
    WHERE episode_of_id IS NULL
  
    UNION ALL
  
    SELECT at.id, at.title, at.season_nr, at.episode_nr
    FROM aka_title at
    JOIN MovieHierarchy mh ON at.episode_of_id = mh.movie_id
),
CoCast AS (
    -- CTE to combine cast for each movie along with person roles
    SELECT c.movie_id, 
           STRING_AGG(CONCAT(n.name, ' (', rt.role, ')'), ', ') AS cast_details,
           COUNT(DISTINCT c.person_id) AS cast_count
    FROM cast_info c
    JOIN name n ON c.person_id = n.id
    JOIN role_type rt ON c.role_id = rt.id
    GROUP BY c.movie_id
),
YearlyProductions AS (
    -- CTE to get production counts per year with a rolling average
    SELECT production_year,
           COUNT(*) AS total_movies,
           AVG(COUNT(*)) OVER (ORDER BY production_year ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) AS rolling_avg
    FROM aka_title
    GROUP BY production_year
    HAVING COUNT(*) > 10 -- Only consider years with more than 10 movies
),
KeywordUsage AS (
    -- CTE to summarize movie keywords with corresponding counts and titles
    SELECT mk.movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords,
           COUNT(*) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    at.title AS movie_title,
    mh.season_nr,
    mh.episode_nr,
    cc.cast_details,
    cc.cast_count,
    yp.total_movies AS productions_this_year,
    yp.rolling_avg AS rolling_average_last_5_years,
    ku.keywords,
    ku.keyword_count,
    COUNT(DISTINCT m.movie_id) AS related_movies_count
FROM aka_title at
LEFT JOIN MovieHierarchy mh ON at.id = mh.movie_id
JOIN CoCast cc ON at.id = cc.movie_id
JOIN YearlyProductions yp ON at.production_year = yp.production_year
LEFT JOIN KeywordUsage ku ON at.id = ku.movie_id
LEFT JOIN aka_title m ON m.episode_of_id = at.id
WHERE at.production_year IS NOT NULL
  AND (mh.season_nr IS NULL OR mh.episode_nr > 0) -- Ensuring only valid episodes
  AND (ku.keyword_count > 2 OR ku.keywords IS NULL) -- Obscure NULL logic based on keywords
GROUP BY at.title, mh.season_nr, mh.episode_nr, cc.cast_details, cc.cast_count, yp.total_movies, yp.rolling_avg, ku.keywords, ku.keyword_count
ORDER BY at.title, mh.season_nr, mh.episode_nr;

