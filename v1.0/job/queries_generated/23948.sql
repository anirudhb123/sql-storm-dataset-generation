WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.kind_id, 
        t.production_year, 
        t.imdb_index, 
        t.episode_of_id,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT 
        t2.id AS title_id,
        t2.title, 
        t2.kind_id, 
        t2.production_year, 
        t2.imdb_index, 
        t2.episode_of_id,
        th.depth + 1
    FROM 
        title_hierarchy th
    JOIN 
        aka_title t2 ON t2.episode_of_id = th.title_id
    WHERE 
        th.depth < 5
),
actor_movies AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT a.name) AS unique_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        km.keyword, 
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword km ON mk.keyword_id = km.id
    GROUP BY 
        mk.movie_id, km.keyword
    HAVING 
        COUNT(mk.keyword_id) > 1
),
performance_benchmark AS (
    SELECT 
        th.title, 
        th.production_year, 
        am.unique_actors, 
        mk.keyword, 
        mk.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY th.production_year ORDER BY mk.keyword_count DESC) AS rank
    FROM 
        title_hierarchy th
    LEFT JOIN 
        actor_movies am ON th.title_id = am.movie_id
    LEFT JOIN 
        movie_keywords mk ON th.title_id = mk.movie_id
)
SELECT 
    pb.title, 
    pb.production_year, 
    COALESCE(pb.unique_actors, 0) AS num_actors, 
    pb.keyword,
    CASE 
        WHEN pb.keyword_count IS NULL THEN 'No keywords'
        WHEN pb.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS keyword_popularity,
    CASE 
        WHEN pb.rank <= 5 THEN 'Top Rank'
        ELSE 'Lower Rank'
    END AS performance_category
FROM 
    performance_benchmark pb
ORDER BY 
    pb.production_year DESC, 
    pb.rank;
