WITH RECURSIVE movie_hierarchy AS (
    -- Recursive CTE to gather movie titles and their hierarchy based on the original movie
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(t.season_nr, 0) AS season_number,
        COALESCE(t.episode_nr, 0) AS episode_number,
        1 AS level
    FROM title m
    LEFT JOIN title t ON m.id = t.episode_of_id

    UNION ALL
    
    SELECT
        t.id AS movie_id,
        t.title,
        COALESCE(t.season_nr, 0),
        COALESCE(t.episode_nr, 0),
        h.level + 1
    FROM title t
    JOIN movie_hierarchy h ON t.episode_of_id = h.movie_id
),
cast_with_roles AS (
    -- CTE to get casts with their respective roles for movies with a specific character 'Hero'
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order 
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    WHERE r.role ILIKE '%Hero%'
),
movie_keywords AS (
    -- CTE to gather movies with specific keywords, such as 'Action' or 'Drama'
    SELECT 
        mk.movie_id,
        k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IN ('Action', 'Drama')
),
selected_movies AS (
    -- CTE to combine previous results and filter based on the keywords and roles
    SELECT
        mh.movie_id,
        mh.title,
        mh.season_number,
        mh.episode_number,
        k.keyword,
        c.actor_name,
        c.role_name,
        c.actor_order
    FROM movie_hierarchy mh
    LEFT JOIN cast_with_roles c ON mh.movie_id = c.movie_id
    LEFT JOIN movie_keywords k ON mh.movie_id = k.movie_id
    WHERE mh.level <= 2 -- A criterion to limit the hierarchy depth to two levels
),
final_summary AS (
    -- Summarize to get distinct movie titles and actors, showing how many roles each actor has played
    SELECT 
        movie_id,
        title,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        COUNT(DISTINCT role_name) AS total_roles,
        COUNT(DISTINCT keyword) AS keyword_count
    FROM selected_movies
    GROUP BY movie_id, title
)
SELECT 
    fs.movie_id,
    fs.title,
    fs.actors,
    fs.total_roles,
    fs.keyword_count,
    CASE 
        WHEN fs.keyword_count > 1 THEN 'Multiple Genres'
        ELSE 'Single Genre'
    END AS genre_description,
    COALESCE(fb.info, 'N/A') AS additional_info
FROM final_summary fs
LEFT JOIN (
    -- Join additional movie information based on the movie_id with NULL handling
    SELECT 
        mi.movie_id,
        mi.info
    FROM movie_info mi
    WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary') 
) fb ON fs.movie_id = fb.movie_id
ORDER BY fs.title ASC;
