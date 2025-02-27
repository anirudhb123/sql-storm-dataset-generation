WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.kind_id,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        1 AS level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.kind_id,
        t.production_year,
        t.season_nr,
        t.episode_nr,
        t.episode_of_id,
        th.level + 1
    FROM 
        title t
    INNER JOIN 
        title_hierarchy th ON th.title_id = t.episode_of_id
),
cast_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT n.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
filtered_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(cs.total_actors, 0) AS total_actors,
        COALESCE(mk.total_keywords, 0) AS total_keywords
    FROM 
        title t
    LEFT JOIN 
        cast_summary cs ON t.id = cs.movie_id
    LEFT JOIN 
        movie_keywords mk ON t.id = mk.movie_id
    WHERE 
        (EXTRACT(YEAR FROM cast('2024-10-01' as date)) - t.production_year) < 10
        OR t.title ILIKE '%(special)%'
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_actors,
    fm.total_keywords,
    CASE 
        WHEN fm.total_actors > 20 THEN 'Ensemble Cast'
        WHEN fm.total_keywords > 5 THEN 'Keyword Rich'
        ELSE 'Moderate'
    END AS classification,
    rank() OVER (PARTITION BY fm.production_year ORDER BY fm.total_actors DESC) AS year_rank,
    RANK() OVER (ORDER BY fm.total_keywords DESC) AS overall_rank
FROM 
    filtered_movies fm
WHERE 
    fm.total_actors > 0
    OR fm.total_keywords > 0
ORDER BY 
    fm.production_year DESC, 
    overall_rank ASC
LIMIT 50;