WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year >= 2000
),
ActorTitles AS (
    SELECT 
        c.person_id,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM cast_info c
    JOIN aka_title t ON c.movie_id = t.movie_id
),
HighRatedActors AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT at.movie_title) AS title_count
    FROM ActorTitles at
    JOIN aka_name a ON at.person_id = a.person_id
    WHERE at.movie_rank = 1 
    GROUP BY a.person_id
    HAVING COUNT(DISTINCT at.movie_title) > 5
)
SELECT 
    a.name AS actor_name,
    at.movie_title,
    at.production_year,
    COALESCE(SUBSTRING(at.movie_title, 1, 10), 'Unknown') AS short_title,
    rt.title_rank,
    CASE 
        WHEN rt.title_rank IS NULL THEN 'No Rank'
        ELSE 'Ranked'
    END AS title_status
FROM HighRatedActors hra
JOIN aka_name a ON hra.person_id = a.person_id
LEFT JOIN RankedTitles rt ON rt.title_id = (
    SELECT MAX(rt_inner.title_id)
    FROM RankedTitles rt_inner
    WHERE rt_inner.production_year = (
        SELECT MAX(r.production_year)
        FROM RankedTitles r
        WHERE r.title_rank <= 2
    )
)
JOIN ActorTitles at ON at.person_id = hra.person_id
WHERE at.production_year = 2020
ORDER BY a.name, at.production_year DESC
OPTION (MAXRECURSION 1000);
