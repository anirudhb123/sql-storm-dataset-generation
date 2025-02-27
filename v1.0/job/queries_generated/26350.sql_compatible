
WITH ranked_movies AS (
    SELECT
        a.title,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names,
        t.production_year,
        t.kind_id
    FROM aka_title a
    JOIN movie_companies mc ON a.movie_id = mc.movie_id
    JOIN aka_name ak ON mc.company_id = ak.person_id
    JOIN cast_info c ON a.movie_id = c.movie_id
    JOIN title t ON a.movie_id = t.id
    LEFT JOIN movie_info mi ON a.movie_id = mi.movie_id
    WHERE t.production_year >= 2000
    AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
    GROUP BY a.title, t.production_year, t.kind_id
),
ranked_companies AS (
    SELECT
        c.name,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT a.title) AS movies
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN aka_title a ON mc.movie_id = a.movie_id
    GROUP BY c.name
),
final_ranking AS (
    SELECT
        rm.title,
        rm.actor_count,
        rm.actor_names,
        rc.name AS company_name,
        rc.movie_count
    FROM ranked_movies rm
    JOIN ranked_companies rc ON rm.actor_count > rc.movie_count
    ORDER BY rm.actor_count DESC, rc.movie_count DESC
)
SELECT
    title,
    actor_count,
    actor_names,
    company_name,
    movie_count
FROM final_ranking
WHERE movie_count > 5
LIMIT 50;
