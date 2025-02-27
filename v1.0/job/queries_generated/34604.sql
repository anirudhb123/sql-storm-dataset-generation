WITH RECURSIVE movie_hierarchy AS (
    -- Recursive CTE to build a hierarchy of movies and their linked movies
    SELECT ml.movie_id, ml.linked_movie_id, 1 AS level
    FROM movie_link ml
    WHERE ml.movie_id IS NOT NULL

    UNION ALL

    SELECT ml.movie_id, ml.linked_movie_id, mh.level + 1
    FROM movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.linked_movie_id
    WHERE mh.level < 5
),
top_movies AS (
    -- CTE to get the top 10 most linked movies based on link_type_id
    SELECT m.id AS movie_id, COUNT(ml.linked_movie_id) AS linkage_count
    FROM movie_link ml
    JOIN title m ON ml.movie_id = m.id
    GROUP BY m.id
    ORDER BY linkage_count DESC
    LIMIT 10
),
cast_details AS (
    -- CTE to retrieve cast information along with related names
    SELECT ci.movie_id, ak.name AS actor_name, COUNT(*) OVER (PARTITION BY ci.movie_id) AS actor_count
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE ak.name IS NOT NULL
),
movie_keywords AS (
    -- CTE to get keywords related to movies
    SELECT mk.movie_id, STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)

SELECT 
    t.title AS movie_title,
    t.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(cd.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(cd.actor_count, 0) AS actor_count,
    (SELECT COUNT(*) FROM movie_link ml WHERE ml.movie_id = t.id) AS total_links,
    CASE 
        WHEN total_links > 5 THEN 'Highly Linked'
        WHEN total_links BETWEEN 2 AND 5 THEN 'Moderately Linked'
        ELSE 'Sparsely Linked'
    END AS linkage_category
FROM title t
LEFT JOIN movie_keywords k ON t.id = k.movie_id
LEFT JOIN cast_details cd ON t.id = cd.movie_id
WHERE t.production_year >= 2000
AND EXISTS (
    SELECT 1
    FROM movie_hierarchy mh
    WHERE mh.movie_id = t.id OR mh.linked_movie_id = t.id
)
ORDER BY t.production_year DESC, t.title;
