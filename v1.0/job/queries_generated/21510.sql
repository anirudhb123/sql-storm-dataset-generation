WITH RECURSIVE movie_hierarchy AS (
    -- Common Table Expression to recursively get movie links
    SELECT m.id AS movie_id, m.title, ml.linked_movie_id, 1 AS depth
    FROM title m
    JOIN movie_link ml ON m.id = ml.movie_id
    WHERE m.production_year >= 2000  -- Focus on movies produced after 2000

    UNION ALL 

    SELECT m.id AS movie_id, m.title, ml.linked_movie_id, depth + 1
    FROM title m
    JOIN movie_link ml ON m.id = ml.movie_id
    JOIN movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    WHERE depth < 3  -- Limit recursion to 3 levels deep
),

-- With clause to gather top cast members
top_cast AS (
    SELECT ci.movie_id, a.name AS actor_name, RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE ci.nr_order IS NOT NULL
),

-- Extracting movie details with some filtering
movies_info AS (
    SELECT mt.movie_id, mt.title, mt.production_year, mt.kind_id, mk.keyword
    FROM title mt
    LEFT JOIN movie_keyword mk ON mt.id = mk.movie_id
    WHERE mt.production_year BETWEEN 2000 AND 2023
)

-- Final selection combining all the gathered data
SELECT
    mh.movie_id,
    mh.title,
    mh.depth,
    COALESCE(tc.actor_name, 'Unknown Actor') AS top_actor,
    MIN(mk.keyword) AS featured_keyword,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    STRING_AGG(DISTINCT a.name, ', ') FILTER (WHERE a.name IS NOT NULL) AS all_actors_in_top_cast
FROM movie_hierarchy mh
LEFT JOIN movies_info mt ON mh.movie_id = mt.movie_id
LEFT JOIN top_cast tc ON tc.movie_id = mh.movie_id AND tc.actor_rank <= 3
LEFT JOIN cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN aka_name a ON ci.person_id = a.person_id
WHERE mh.linked_movie_id IS NOT NULL -- Ensuring we only have linked movies
GROUP BY mh.movie_id, mh.title, mh.depth
ORDER BY mh.depth DESC, mh.title;
