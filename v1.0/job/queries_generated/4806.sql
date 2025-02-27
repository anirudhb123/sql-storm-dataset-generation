WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ac.actor_count, 0) AS total_actors,
        COALESCE(GROUP_CONCAT(DISTINCT k.keyword), 'No Keywords') AS keywords
    FROM aka_title m
    LEFT JOIN ActorCounts ac ON m.id = ac.movie_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id, m.title, ac.actor_count
)
SELECT 
    md.title,
    md.production_year,
    md.total_actors,
    RT.title_rank,
    md.keywords
FROM MovieDetails md
LEFT JOIN RankedTitles RT ON md.title = RT.title
WHERE (md.total_actors > 5 OR md.keywords LIKE '%Action%') 
   AND (md.production_year IS NULL OR md.production_year > 2000)
ORDER BY md.total_actors DESC, RT.title_rank
LIMIT 100;
