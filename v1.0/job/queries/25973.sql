WITH ranked_movies AS (
    SELECT title.id AS movie_id,
           title.title,
           title.production_year,
           COUNT(DISTINCT cast_info.person_id) AS total_cast,
           STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names,
           ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM title
    JOIN movie_companies ON title.id = movie_companies.movie_id
    JOIN company_name ON movie_companies.company_id = company_name.id
    JOIN cast_info ON title.id = cast_info.movie_id
    JOIN aka_name ON cast_info.person_id = aka_name.person_id
    WHERE title.production_year > 2000
    GROUP BY title.id, title.title, title.production_year
),
popular_movies AS (
    SELECT movie_id, title, production_year, total_cast, cast_names
    FROM ranked_movies
    WHERE rank <= 5
)
SELECT pm.production_year,
       COUNT(pm.movie_id) AS total_movies,
       SUM(pm.total_cast) AS total_cast_members,
       STRING_AGG(pm.title, '; ') AS titles,
       STRING_AGG(pm.cast_names, '; ') AS all_cast_names
FROM popular_movies pm
GROUP BY pm.production_year
ORDER BY pm.production_year DESC;
