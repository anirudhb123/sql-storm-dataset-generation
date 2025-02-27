WITH RECURSIVE cast_hierarchy AS (
    SELECT ci.id as cast_id, ci.movie_id, ci.person_id, ci.nr_order, 
           1 as level, 
           ak.name as actor_name
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    WHERE ci.nr_order = 1
    
    UNION ALL
    
    SELECT ci.id as cast_id, ci.movie_id, ci.person_id, ci.nr_order, 
           ch.level + 1, 
           ak.name as actor_name
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN cast_hierarchy ch ON ci.movie_id = ch.movie_id AND ci.nr_order = ch.nr_order + 1
),
ranked_movies AS (
    SELECT ct.movie_id, 
           tit.title, 
           tit.production_year, 
           ROW_NUMBER() OVER (PARTITION BY ct.movie_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) as actor_rank
    FROM cast_info ci
    JOIN title tit ON ci.movie_id = tit.id
    JOIN complete_cast cc ON cc.movie_id = ci.movie_id 
    LEFT JOIN company_name cn ON cn.id = (
        SELECT mc.company_id 
        FROM movie_companies mc 
        WHERE mc.movie_id = ci.movie_id 
        LIMIT 1
    )
    GROUP BY ct.movie_id, tit.title, tit.production_year
),
agg_genre AS (
    SELECT mt.movie_id, 
           LISTAGG(kt.keyword, ', ') AS genres
    FROM movie_keyword mt
    JOIN keyword kt ON mt.keyword_id = kt.id
    GROUP BY mt.movie_id
)
SELECT mh.movie_id,
       tit.title,
       mh.production_year,
       ak.actor_name,
       COALESCE(genres, 'No Genre') AS genres,
       COUNT(DISTINCT ci.person_id) AS total_actor_count,
       SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count,
       AVG(mvi.info) AS average_rating
FROM ranked_movies mh
JOIN cast_hierarchy ch ON mh.movie_id = ch.movie_id
LEFT JOIN agg_genre g ON mh.movie_id = g.movie_id
JOIN movie_info mvi ON mvi.movie_id = mh.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
JOIN aka_name ak ON ch.person_id = ak.person_id
WHERE mh.actor_rank = 1
GROUP BY mh.movie_id, tit.title, mh.production_year, ak.actor_name, genres
ORDER BY mh.production_year DESC, total_actor_count DESC
LIMIT 100;

This SQL query consists of multiple complex constructs:

1. **Recursive CTE** to derive a hierarchy of cast members based on their appearance order in movies.
2. **Window functions** are used to determine the top actor for each movie.
3. **LEFT JOINs** are utilized to gather related information while allowing NULLs for optional data.
4. **Aggregative functions** to compute actor counts and note counts.
5. Our query involves complex GROUP BY clauses and string operations with `LISTAGG` to consolidate genre keywords.
6. The use of COALESCE functions ensures robustness where NULL values may exist.
7. **Subqueries** maintain context for specific filtering conditions.

This combination allows benchmarking of query execution for performance evaluation based on the intricacies of the SQL schema provided.
