WITH RECURSIVE movie_hierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS depth
    FROM aka_title m
    WHERE m.production_year >= 2000  -- Starting from the year 2000
    UNION ALL
    SELECT m.id, m.title, m.production_year, mh.depth + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE mh.depth < 3  -- Limit recursion depth to prevent excessive joins
),
actor_movies AS (
    SELECT ci.movie_id, COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    WHERE an.name IS NOT NULL -- Ensure names are not NULL
    GROUP BY ci.movie_id
),
movie_keywords AS (
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COALESCE(am.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    ROW_NUMBER() OVER (ORDER BY h.production_year DESC, h.title) AS ranking
FROM movie_hierarchy h
LEFT JOIN actor_movies am ON h.movie_id = am.movie_id
LEFT JOIN movie_keywords mk ON h.movie_id = mk.movie_id
WHERE h.depth = 2 -- Only consider movies that are part of the second level of hierarchy
  AND (h.production_year IS NOT NULL OR am.actor_count > 0) -- Filter condition
ORDER BY h.production_year DESC, h.title;

This SQL query performs an elaborate analysis on movies produced from the year 2000 onward, utilizing a recursive CTE to explore linked movies up to a depth of 2, while also aggregating the actor counts and collecting keywords associated with each movie. The resultant dataset is ordered by production year and title, with a ranking allocated to each entry.
