WITH Recursive ActorHierarchy AS (
    SELECT ci.person_id AS actor_id, 
           t.title AS movie_title, 
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY ci.person_id ORDER BY t.production_year DESC) AS role_rank
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
    JOIN aka_title at ON ci.movie_id = at.movie_id
    JOIN title t ON at.id = t.id
    WHERE an.name IS NOT NULL 
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
),
ActorAwards AS (
    SELECT a.id AS actor_id,
           COUNT(DISTINCT aaw.award_id) AS awards_count
    FROM actor a
    LEFT JOIN awards aaw ON a.id = aaw.actor_id
    GROUP BY a.id
),
MovieStatistics AS (
    SELECT m.movie_id,
           AVG(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS average_cast_order,
           COUNT(DISTINCT k.keyword) AS keyword_count
    FROM aka_title m
    LEFT JOIN cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN movie_keyword k ON m.movie_id = k.movie_id
    GROUP BY m.movie_id
),
AwardsFiltered AS (
    SELECT actor_id, 
           COUNT(DISTINCT award_id) AS filtered_awards
    FROM ActorAwards
    WHERE awards_count > 0 
    GROUP BY actor_id
)
SELECT ah.actor_id,
       ah.movie_title,
       ah.production_year,
       ms.average_cast_order,
       COALESCE(aaw.filtered_awards, 0) AS awards_count,
       COUNT(DISTINCT k.keyword) AS associated_keywords
FROM ActorHierarchy ah
JOIN MovieStatistics ms ON ah.movie_id = ms.movie_id
LEFT JOIN AwardsFiltered aaw ON ah.actor_id = aaw.actor_id
LEFT JOIN movie_keyword k ON ah.movie_id = k.movie_id
WHERE ah.role_rank <= 3
GROUP BY ah.actor_id, ah.movie_title, ah.production_year, ms.average_cast_order, aaw.filtered_awards
ORDER BY ah.production_year DESC, awards_count DESC NULLS LAST
LIMIT 100;

This SQL query performs a benchmarking task across multiple facets of movie-related data, involving joins, CTEs, window functions, and aggregation, thus showcasing complex SQL capabilities. It effectively filters, groups, and ranks data concerning actors and their contributions to various films and awards.
