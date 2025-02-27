WITH actor_movie AS (
    SELECT 
        ak.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS movie_rank,
        cmt.kind AS movie_kind,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT c.id) AS cast_count
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN aka_title mt ON c.movie_id = mt.movie_id
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN kind_type cmt ON mt.kind_id = cmt.id
    WHERE c.note IS NULL OR c.note <> 'Cameo'
    GROUP BY ak.name, mt.title, mt.production_year, cmt.kind
),
movie_info_extended AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        GROUP_CONCAT(CONCAT(mi.info, ' [', it.info, ']')) AS additional_info
    FROM aka_title mt
    LEFT JOIN movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    GROUP BY mt.id, mt.title, mt.production_year
),
ranked_movies AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.movie_rank,
        me.additional_info,
        am.keywords,
        am.cast_count,
        RANK() OVER (PARTITION BY am.actor_name ORDER BY am.movie_rank) AS actor_movie_rank
    FROM actor_movie am
    JOIN movie_info_extended me ON am.movie_title = me.title 
                                  AND am.production_year = me.production_year
)
SELECT 
    r.actor_name,
    r.movie_title,
    r.production_year,
    r.additional_info,
    COALESCE(r.keywords, '{}') AS keywords,
    r.cast_count,
    CASE 
        WHEN r.actor_movie_rank = 1 THEN 'Recent Lead Actor'
        WHEN r.cast_count > 5 THEN 'Seasoned Actor'
        ELSE 'Emerging Talent'
    END AS actor_category
FROM ranked_movies r
WHERE r.movie_rank <= 3
  AND r.production_year >= (SELECT MAX(production_year) - 5 FROM aka_title WHERE kind_id = (SELECT id FROM kind_type WHERE kind = 'movie'))
ORDER BY r.actor_name, r.production_year DESC;

### Explanation:
- The query begins with a Common Table Expression (CTE) named `actor_movie` that aggregates actor information including the total number of cast members for each movie, and it uses `ROW_NUMBER()` to rank movies for each actor based on the year.
- A second CTE, `movie_info_extended`, is created to summarize additional movie information by grouping related attributes together.
- A final CTE, `ranked_movies`, combines actor and movie information along with rankings using `RANK()`.
- The final `SELECT` statement pulls data from `ranked_movies`, applying COALESCE to handle NULL values in keywords and utilizing a CASE statement to categorize actors based on their career status.
- The query includes a complex WHERE condition using a correlated subquery to filter only recently produced movies in the last five years from the maximum production year.
- The results are ordered by actor names and production year.
