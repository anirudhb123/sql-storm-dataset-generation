WITH ranked_movies AS (
    SELECT t.id AS movie_id,
           t.title,
           t.production_year,
           k.keyword,
           ARRAY_AGG(DISTINCT name.name) AS actor_names,
           ARRAY_AGG(DISTINCT cct.kind) AS company_types,
           ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT name.id) DESC) AS actor_rank
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name name ON ci.person_id = name.person_id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_type cct ON mc.company_type_id = cct.id
    GROUP BY t.id, t.title, t.production_year, k.keyword
),
filtered_movies AS (
    SELECT *,
           STRING_AGG(DISTINCT actor_names::text, ', ') AS all_actors,
           STRING_AGG(DISTINCT company_types::text, ', ') AS all_companies
    FROM ranked_movies
    WHERE actor_rank <= 3  -- select only movies with top 3 ranked actors
    GROUP BY movie_id, title, production_year, keyword
)

SELECT fm.title,
       fm.production_year,
       fm.keyword,
       fm.all_actors,
       fm.all_companies
FROM filtered_movies fm
WHERE fm.production_year >= 2000
ORDER BY fm.production_year DESC, fm.title;
