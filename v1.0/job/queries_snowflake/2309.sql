
WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        0 AS depth
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL
    UNION ALL
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        th.depth + 1
    FROM 
        title t
    JOIN 
        TitleHierarchy th ON t.episode_of_id = th.title_id
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ci.nr_order,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.nr_order IS NOT NULL
),
FinalResults AS (
    SELECT 
        th.title,
        th.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        LISTAGG(fc.actor_name, ', ' ORDER BY fc.nr_order) AS actors,
        COUNT(DISTINCT fc.actor_name) AS total_actors,
        COUNT(DISTINCT fc.nr_order) AS unique_actor_orders
    FROM 
        TitleHierarchy th
    LEFT JOIN 
        MoviesWithKeywords mk ON th.title_id = mk.movie_id
    LEFT JOIN 
        FilteredCast fc ON th.title_id = fc.movie_id
    GROUP BY 
        th.title, th.production_year, mk.keywords
)
SELECT 
    *,
    CASE 
        WHEN total_actors > 10 THEN 'Epic Cast'
        WHEN total_actors BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_category
FROM 
    FinalResults
WHERE 
    production_year >= 2000 AND 
    (keywords IS NOT NULL OR keywords <> 'No Keywords')
ORDER BY 
    production_year DESC, title ASC;
