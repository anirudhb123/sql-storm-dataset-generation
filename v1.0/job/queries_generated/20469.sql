WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(aka.name, ''), 'Unknown') AS known_name,
        CASE 
            WHEN t.season_nr IS NOT NULL THEN CONCAT('Season ', t.season_nr, ', Episode ', t.episode_nr)
            ELSE 'N/A' 
        END AS season_info,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name aka ON aka.id = t.id
    WHERE 
        t.production_year IS NOT NULL
    UNION ALL
    SELECT 
        t.id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(aka.name, ''), 'Unknown') AS known_name,
        CASE 
            WHEN t.season_nr IS NOT NULL THEN CONCAT('Season ', t.season_nr, ', Episode ', t.episode_nr)
            ELSE 'N/A' 
        END AS season_info,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        title_hierarchy th ON t.episode_of_id = th.id
    WHERE 
        th.production_year IS NOT NULL
),
actor_summary AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT th.title, ', ') AS movies
    FROM 
        cast_info ci
    JOIN 
        title_hierarchy th ON th.id = ci.movie_id
    GROUP BY 
        ci.person_id
),
actor_details AS (
    SELECT 
        n.id AS person_id,
        n.name,
        COALESCE(asum.movie_count, 0) AS movie_count,
        asum.movies
    FROM 
        name n
    LEFT JOIN 
        actor_summary asum ON asum.person_id = n.imdb_id
    WHERE 
        n.gender = 'F' 
        AND (asum.movie_count > 0 OR n.name IS NULL)
)
SELECT 
    ad.name,
    ad.movie_count,
    ad.movies,
    th.title,
    th.production_year,
    CASE 
        WHEN th.title_rank > 10 THEN 'Top 10 Not Reached'
        ELSE 'Top 10'
    END AS title_rank_status
FROM 
    actor_details ad
JOIN 
    title_hierarchy th ON th.known_name = ad.name
WHERE 
    th.production_year BETWEEN 2000 AND 2023
ORDER BY 
    ad.movie_count DESC,
    th.production_year DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;

-- Note: Adjust NULL handling and ranking logic to reflect the peculiarities of the data you are analyzing.
