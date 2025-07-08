WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ak.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    GROUP BY ak.person_id
),
FilteredMovies AS (
    SELECT 
        mt.movie_id,
        mt.info,
        m.title AS movie_title
    FROM movie_info mt
    JOIN title m ON mt.movie_id = m.id
    WHERE mt.info_type_id IN (SELECT id FROM info_type WHERE info = 'Plot')
),
CompanyWithMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
    HAVING COUNT(DISTINCT mc.company_id) > 1
),
OuterJoinResults AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        COALESCE(ac.movie_count, 0) AS actor_movie_count,
        COALESCE(cm.company_count, 0) AS company_movie_count
    FROM RankedTitles rt
    LEFT JOIN ActorCounts ac ON rt.title_id = ac.person_id
    LEFT JOIN CompanyWithMovies cm ON rt.title_id = cm.movie_id
)
SELECT 
    o.title,
    o.production_year,
    o.actor_movie_count,
    o.company_movie_count,
    CASE 
        WHEN o.actor_movie_count > 5 AND o.company_movie_count > 5 THEN 'Highly Collaborated'
        WHEN o.actor_movie_count = 0 AND o.company_movie_count = 0 THEN 'Abandoned'
        WHEN o.actor_movie_count IS NULL OR o.company_movie_count IS NULL THEN 'Data Incomplete'
        ELSE 'Average Engagement' 
    END AS Engagement_Status
FROM OuterJoinResults o
WHERE o.production_year BETWEEN 2000 AND 2020
ORDER BY o.production_year DESC, o.title
LIMIT 50;
