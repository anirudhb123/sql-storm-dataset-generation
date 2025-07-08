WITH filtered_titles AS (
    SELECT t.id AS title_id, t.title, t.production_year, k.keyword
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword ILIKE '%drama%'
),
actor_contributions AS (
    SELECT a.name AS actor_name, COUNT(ci.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY a.name
),
movie_details AS (
    SELECT t.id AS movie_id, t.title, t.production_year, company.name AS company_name
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name company ON mc.company_id = company.id
    WHERE t.production_year BETWEEN 2000 AND 2023
),
rated_movies AS (
    SELECT movie_details.*, actor_contributions.actor_name, actor_contributions.movie_count
    FROM movie_details
    JOIN actor_contributions ON movie_details.movie_id IN (
        SELECT ci.movie_id
        FROM cast_info ci
        WHERE ci.person_role_id = (SELECT id FROM role_type WHERE role = 'lead')
    )
)
SELECT rated_movies.title, rated_movies.production_year, rated_movies.company_name, rated_movies.actor_name, rated_movies.movie_count
FROM rated_movies
ORDER BY rated_movies.production_year DESC, rated_movies.movie_count DESC;
