WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(episode.of_id, -1) AS episode_of_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        aka_title episode ON mt.id = episode.episode_of_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(episode.of_id, -1) AS episode_of_id,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_hierarchy mh ON mt.episode_of_id = mh.movie_id
), ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM 
        movie_hierarchy mh
), named_movies AS (
    SELECT 
        nm.name AS actor_name, 
        rv.title AS movie_title, 
        rv.production_year AS year_of_release
    FROM 
        ranked_movies rv
    INNER JOIN 
        cast_info ci ON rv.movie_id = ci.movie_id
    INNER JOIN 
        aka_name nm ON ci.person_id = nm.person_id
    WHERE 
        nm.name IS NOT NULL
    AND 
        rv.rank <= 5
), company_info AS (
    SELECT 
        mc.movie_id,
        cc.name AS company_name,
        cc.country_code,
        mc.note
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cc ON mc.company_id = cc.id
), filtered_movies AS (
    SELECT 
        nm.actor_name,
        nm.movie_title,
        nm.year_of_release,
        coalesce(ci.company_name, 'Unknown') AS company_name
    FROM 
        named_movies nm
    LEFT JOIN 
        company_info ci ON nm.movie_title = ci.movie_id
    WHERE 
        nm.year_of_release > 2000
    AND 
        nm.actor_name NOT LIKE '%Smith%'
    AND 
        (nm.year_of_release - EXTRACT(YEAR FROM CURRENT_DATE) <= 0 OR ci.country_code IS NULL)
)
SELECT 
    actor_name,
    movie_title,
    year_of_release,
    CONCAT('Produced by: ', company_name) AS production_info
FROM 
    filtered_movies
WHERE 
    actor_name LIKE '%John%' OR actor_name LIKE '%Doe%'
ORDER BY 
    year_of_release DESC, actor_name;
