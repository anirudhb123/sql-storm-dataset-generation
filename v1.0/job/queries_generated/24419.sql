WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank_order,
        COUNT(*) OVER (PARTITION BY at.production_year) AS total_movies
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
), 
ActorCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), 
ComplexJoin AS (
    SELECT 
        t.title, 
        t.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        RANK() OVER (ORDER BY COALESCE(ac.actor_count, 0) DESC, t.production_year DESC) AS rank_by_actor_count
    FROM 
        RankedMovies t
    LEFT JOIN 
        ActorCounts ac ON t.title_id = ac.movie_id
    WHERE 
        t.rank_order <= 5 -- Selecting top 5 titles per year for further complexity
), 
NullHandled AS (
    SELECT 
        *,
        CASE 
            WHEN actor_count IS NULL THEN 'No Actors'
            WHEN actor_count = 0 THEN 'No Actors Listed'
            ELSE 'Has Actors'
        END AS actor_status
    FROM 
        ComplexJoin
)

SELECT 
    nh.title,
    nh.production_year,
    nh.actor_count,
    nh.actor_status,
    CASE 
        WHEN nh.actor_count = 0 THEN 'N/A' 
        ELSE CONCAT(nh.actor_count, ' Actor(s)') 
    END AS actor_description
FROM 
    NullHandled nh
WHERE
    nh.actor_count >= 1
ORDER BY 
    nh.production_year DESC, 
    nh.actor_count DESC
LIMIT 10;

-- Additional statistics about the movies
UNION ALL

SELECT 
    'Statistics Summary' AS title,
    NULL AS production_year,
    COUNT(*) AS total_titles,
    NULL AS actor_status,
    NULL AS actor_description
FROM 
    aka_title;

-- Final touch with NULL logic on the left join scenarios
LEFT JOIN (
    SELECT 
        mi.movie_id, 
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
    FROM 
        movie_keyword mi
    JOIN 
        keyword ki ON mi.keyword_id = ki.id
    GROUP BY 
        mi.movie_id
) AS keywords_summary 
ON 
    keywords_summary.movie_id = nh.title_id;
