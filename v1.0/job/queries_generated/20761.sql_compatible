
WITH ranked_movies AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        aka_name.name AS actor_name,
        COUNT(*) OVER (PARTITION BY title.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY aka_name.name) AS actor_rank
    FROM title
    INNER JOIN complete_cast ON complete_cast.movie_id = title.id
    INNER JOIN aka_name ON aka_name.person_id = complete_cast.subject_id
),
actor_movie_counts AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        MAX(production_year) AS last_movie_year
    FROM ranked_movies
    GROUP BY actor_name
),
movies_with_keywords AS (
    SELECT
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword
    FROM title m
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
)
SELECT 
    amc.actor_name,
    amc.total_movies,
    amc.last_movie_year,
    STRING_AGG(DISTINCT mwk.movie_keyword, ', ') AS keywords,
    COUNT(DISTINCT mwk.movie_title) AS movies_with_keywords,
    CASE 
        WHEN SUM(CASE WHEN mwk.movie_keyword IS NOT NULL THEN 1 ELSE 0 END) > 5 THEN 'More than five keywords'
        ELSE 'Five or fewer keywords'
    END AS keyword_threshold,
    MAX(CASE WHEN appl.production_year BETWEEN 2000 AND 2023 THEN 1 END) AS appeared_in_2000s
FROM actor_movie_counts amc
LEFT JOIN movies_with_keywords mwk ON mwk.movie_title IN (SELECT ranked_movies.movie_title FROM ranked_movies WHERE ranked_movies.actor_name = amc.actor_name)
LEFT JOIN ranked_movies appl ON appl.actor_name = amc.actor_name
GROUP BY amc.actor_name, amc.total_movies, amc.last_movie_year
ORDER BY amc.total_movies DESC, amc.actor_name ASC
LIMIT 50;
