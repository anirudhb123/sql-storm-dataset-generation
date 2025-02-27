WITH RECURSIVE movie_hierarchy AS (
    SELECT mt.movie_id, mt.title, mt.production_year, 
           1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT mt.movie_id, mt.title, mt.production_year, 
           mh.level + 1
    FROM movie_link mlink
    JOIN movie_hierarchy mh ON mlink.movie_id = mh.movie_id
    JOIN aka_title mt ON mlink.linked_movie_id = mt.id
    WHERE mh.level < 5
),
ranked_cast AS (
    SELECT ci.movie_id, a.name AS actor_name, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
),
movie_keywords AS (
    SELECT mt.movie_id, 
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
)
SELECT mh.movie_id, mh.title, mh.production_year, 
       rc.actor_name, 
       COALESCE(mk.keywords, 'No Keywords') AS keywords, 
       mh.level
FROM movie_hierarchy mh
LEFT JOIN ranked_cast rc ON mh.movie_id = rc.movie_id AND rc.actor_rank <= 3
LEFT JOIN movie_keywords mk ON mh.movie_id = mk.movie_id
WHERE mh.production_year >= 2000
ORDER BY mh.production_year DESC, mh.title;

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - `movie_hierarchy`: Recursively fetches movies and their child linked movies up to a maximum level of 5 from the `movie_link` table.
   - `ranked_cast`: Ranks actors based on their order in the cast list for each movie, limiting to 3 top-ranked actors using the `ROW_NUMBER()` window function.
   - `movie_keywords`: Aggregates keywords for movies into a comma-separated string for easy readability.

2. **Main Query**:
   - Joins the results of the CTEs to create a comprehensive output that includes the movie's title, production year, the actor's name, keywords associated with the movie, and the hierarchy level of the movie in relation to linked movies.
   - Uses a `LEFT JOIN` to ensure that even if there are no actors or keywords for a particular movie, the movie will still appear in the results, substituting NULLs with 'No Keywords'.
   - Filters the final results to include only movies produced from the year 2000 onwards, ordering them by year in descending order and then by title.

This query combines various SQL constructs to create a performance benchmark that can test the efficiency of handling complex relationships and aggregations within the provided schema.
