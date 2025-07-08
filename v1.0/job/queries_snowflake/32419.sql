
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(t.title, 'N/A') AS title_with_episode,
        COALESCE(t.season_nr, 0) AS season_number,
        COALESCE(t.episode_nr, 0) AS episode_number,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        aka_title t ON m.id = t.episode_of_id
),
ranked_movies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.title_with_episode,
        mh.season_number,
        mh.episode_number,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank
    FROM
        movie_hierarchy mh
)
SELECT
    rm.production_year,
    COUNT(rm.movie_id) AS number_of_movies,
    LISTAGG(DISTINCT rm.title_with_episode, ', ') WITHIN GROUP (ORDER BY rm.title_with_episode) AS titles,
    AVG(NULLIF(DATE_PART(YEAR, '2024-10-01'::DATE) - rm.production_year, 0)) AS avg_year_difference
FROM
    ranked_movies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE
    cn.country_code IS NOT NULL AND
    rm.season_number = 0 AND 
    rm.rank <= 5 
GROUP BY
    rm.production_year
ORDER BY
    rm.production_year DESC
LIMIT 10;
