WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.movie_info_count DESC) AS rank,
        COALESCE(m.movie_info_count, 0) AS movie_info_count
    FROM title t
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS movie_info_count 
        FROM movie_info 
        GROUP BY movie_id
    ) m ON t.id = m.movie_id
),
ActorRoleCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS actor_roles
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
FinalResults AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        ac.actor_roles,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM RankedMovies rm
    LEFT JOIN ActorRoleCounts ac ON rm.title_id = ac.movie_id
    LEFT JOIN KeywordCounts kc ON rm.title_id = kc.movie_id
)
SELECT 
    title_id, 
    title, 
    production_year,
    actor_count,
    actor_roles,
    keyword_count
FROM FinalResults
WHERE 
    (production_year > 2000 AND actor_count > 5) OR 
    (production_year <= 2000 AND keyword_count > 3)
ORDER BY 
    production_year DESC,
    actor_count DESC,
    title_id ASC;
