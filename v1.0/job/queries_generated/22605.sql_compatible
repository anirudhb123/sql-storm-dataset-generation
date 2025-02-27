
WITH RecursiveTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(t.season_nr, 0) AS season_nr,
        COALESCE(t.episode_nr, 0) AS episode_nr,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.season_nr, t.episode_nr) AS rn
    FROM 
        aka_title t
),

ActorTitleStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_movies_with_notes,
        SUM(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS total_order,
        STRING_AGG(DISTINCT at.title, ', ') AS titles,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS rank
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        RecursiveTitles at ON c.movie_id = at.title_id
    GROUP BY 
        a.person_id
),

PivotStats AS (
    SELECT 
        ats.person_id,
        ats.total_movies,
        ats.avg_movies_with_notes,
        CASE 
            WHEN ats.total_movies > 0 THEN CAST(ats.total_order AS FLOAT) / ats.total_movies
            ELSE 0
        END AS avg_order_per_movie,
        ats.titles
    FROM 
        ActorTitleStats ats
    WHERE 
        ats.total_movies > 5
),

ActorRankings AS (
    SELECT 
        p.person_id,
        p.name AS actor_name,
        ps.total_movies,
        ps.avg_movies_with_notes,
        ps.avg_order_per_movie,
        RANK() OVER (ORDER BY ps.avg_order_per_movie DESC) AS performance_rank
    FROM 
        aka_name p
    JOIN 
        PivotStats ps ON p.person_id = ps.person_id
)

SELECT 
    ar.actor_name,
    ar.total_movies,
    ar.avg_movies_with_notes,
    ar.avg_order_per_movie,
    ar.performance_rank,
    (
        SELECT COUNT(DISTINCT c.movie_id)
        FROM cast_info c
        WHERE c.person_id = ar.person_id
        AND EXISTS (
            SELECT 1 FROM movie_info m
            WHERE m.movie_id = c.movie_id AND m.info_type_id IS NOT NULL
        )
    ) AS movies_with_info_count
FROM 
    ActorRankings ar
ORDER BY 
    ar.performance_rank
LIMIT 10;
