WITH actor_movie_count AS (
    SELECT ci.person_id, COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY ci.person_id
),
top_actors AS (
    SELECT amc.person_id, an.name, amc.movie_count
    FROM actor_movie_count amc
    JOIN aka_name an ON amc.person_id = an.person_id
    WHERE amc.movie_count > 5
    ORDER BY amc.movie_count DESC
    LIMIT 10
),
movie_details AS (
    SELECT at.title, at.production_year, mv.company_count
    FROM aka_title at
    LEFT JOIN (
        SELECT movie_id, COUNT(DISTINCT company_id) AS company_count
        FROM movie_companies
        GROUP BY movie_id
    ) mv ON at.movie_id = mv.movie_id
    WHERE at.production_year BETWEEN 2000 AND 2020
)
SELECT ta.name, md.title, md.production_year, COALESCE(md.company_count, 0) AS company_count
FROM top_actors ta
JOIN cast_info ci ON ta.person_id = ci.person_id
JOIN movie_details md ON ci.movie_id IN (SELECT movie_id FROM aka_title WHERE title LIKE '%Adventure%')
WHERE EXISTS (
    SELECT 1
    FROM movie_info mi
    WHERE mi.movie_id = ci.movie_id AND mi.info_type_id IN (
        SELECT id FROM info_type WHERE info LIKE '%Oscar%'
    )
)
ORDER BY md.production_year DESC, ta.movie_count DESC;
