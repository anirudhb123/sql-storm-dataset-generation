WITH LatestMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ARRAY_AGG(DISTINCT t.title) AS movie_titles,
        COUNT(DISTINCT t.id) AS movie_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE t.production_year >= 2000
    GROUP BY a.id, a.name
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
ActorRankings AS (
    SELECT
        lm.actor_id,
        lm.actor_name,
        lm.movie_count,
        cs.company_count,
        DENSE_RANK() OVER (ORDER BY lm.movie_count DESC) AS actor_rank
    FROM LatestMovies lm
    LEFT JOIN CompanyStats cs ON lm.movie_titles && (SELECT ARRAY_AGG(title) FROM title WHERE id IN (SELECT movie_id FROM cast_info WHERE person_id = lm.actor_id))  
)
SELECT 
    ar.actor_id,
    ar.actor_name,
    ar.movie_count,
    ar.company_count,
    ar.actor_rank,
    (SELECT COUNT(*) FROM actor_rankings) AS total_actors 
FROM ActorRankings ar
WHERE ar.company_count IS NOT NULL
OR ar.movie_count > 5
ORDER BY ar.actor_rank, ar.actor_name;
