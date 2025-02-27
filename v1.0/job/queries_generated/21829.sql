WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
),
actor_movie_count AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    GROUP BY c.person_id
),
names_with_movies AS (
    SELECT 
        a.person_id,
        a.name,
        COALESCE(am.movie_count, 0) AS movie_count
    FROM aka_name a
    LEFT JOIN actor_movie_count am ON a.person_id = am.person_id
),
most_productive_actors AS (
    SELECT 
        nwm.person_id,
        nwm.name,
        nwm.movie_count,
        RANK() OVER (ORDER BY nwm.movie_count DESC) AS rank
    FROM names_with_movies nwm
    WHERE nwm.movie_count > 0
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    mt.title,
    mt.production_year,
    paa.name AS actor_name,
    mk.keywords_list,
    CASE 
        WHEN paa.movie_count IS NULL THEN 'Unknown Actor'
        ELSE paa.movie_count::text || ' movies'
    END AS movie_credits
FROM ranked_titles mt
LEFT JOIN most_productive_actors paa ON mt.year_rank = 1 AND paa.rank <= 5
LEFT JOIN movie_keywords mk ON mt.title_id = mk.movie_id
WHERE mt.production_year BETWEEN 2000 AND 2020
  AND (mk.keywords_list IS NULL OR mk.keywords_list LIKE '%Drama%')
ORDER BY mt.production_year, paa.movie_count DESC NULLS LAST;

### Explanation:

- The query begins with several Common Table Expressions (CTEs): 
    - **ranked_titles** ranks titles by production year.
    - **actor_movie_count** counts the distinct movies per actor.
    - **names_with_movies** selects actor names along with their movie counts, defaulting to 0 if they have none.
    - **most_productive_actors** ranks actors based on their movie counts.
    - **movie_keywords** aggregates keywords for each movie.

- The final SELECT pulls data from titles, the most productive actors for each year, and any related keywords while applying filtering for the production years and specific keyword criteria.

- Edge cases are handled by using `COALESCE` to replace NULL counts with 0 and a case statement to describe actors with no credits creatively as "Unknown Actor".

This SQL query is designed to highlight actors with the most credits in the 21st century while showcasing movie titles that have “Drama” in their keywords where applicable.
