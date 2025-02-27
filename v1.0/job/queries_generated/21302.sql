WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt_seasons.season_nr, 0) AS season_num,
        COALESCE(mt_seasons.episode_nr, 0) AS episode_num,
        COALESCE(cast.person_id, 0) AS cast_member
    FROM 
        aka_title mt
    LEFT JOIN 
        title t ON mt.movie_id = t.id
    LEFT JOIN 
        movie_link ml ON mb.id = ml.movie_id
    LEFT JOIN 
        title t_linked ON ml.linked_movie_id = t_linked.id
    LEFT JOIN 
        complete_cast cc ON mt.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info cast ON cc.subject_id = cast.person_id
    LEFT JOIN 
        (SELECT 
            episode_of_id, season_nr, episode_nr 
         FROM 
            aka_title
         WHERE 
            kind_id = (SELECT id FROM kind_type WHERE kind = 'tv series')) mt_seasons ON mt_seasons.episode_of_id = mt.movie_id
    WHERE 
        mt.production_year IS NOT NULL
), benchmark_stats AS (
    SELECT 
        movie_id,
        title,
        production_year,
        season_num,
        episode_num,
        COUNT(DISTINCT cast_member) AS total_cast,
        STRING_AGG(DISTINCT (SELECT name FROM aka_name WHERE person_id = cast_member), ', ') AS cast_list
    FROM 
        movie_hierarchy
    GROUP BY 
        movie_id, title, production_year, season_num, episode_num
), ranked_movies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS cast_rank,
        SUM(total_cast) OVER (PARTITION BY production_year) AS total_cast_in_year
    FROM 
        benchmark_stats
)
SELECT 
    *,
    CASE
        WHEN total_cast IS NULL THEN 'No cast members'
        ELSE CONCAT('Total Cast Members: ', total_cast)
    END AS cast_member_info,
    CASE
        WHEN season_num > 0 THEN 'Seasonal'
        ELSE 'Feature Length'
    END AS movie_type
FROM 
    ranked_movies
WHERE 
    total_cast > 0
ORDER BY 
    production_year DESC, cast_rank ASC;
