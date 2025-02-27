
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COUNT(CASE WHEN k.keyword IS NOT NULL THEN 1 END) OVER (PARTITION BY a.id) AS keyword_count
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE a.kind_id IN (SELECT id FROM kind_type WHERE kind NOT LIKE '%episode%')
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        keyword_count
    FROM RankedMovies
    WHERE rn <= 5
),
ActorMovieCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM cast_info c
    GROUP BY c.movie_id
),
CompaniesWithMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(co.name, ', ') AS company_names,
        COUNT(DISTINCT co.id) AS company_count
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.keyword_count,
    a.actor_count,
    cm.company_names,
    cm.company_count,
    CASE 
        WHEN fm.keyword_count > 0 THEN 'Has Keywords'
        ELSE 'No Keywords'
    END AS keyword_status,
    CASE 
        WHEN a.actor_count = 0 THEN NULL
        ELSE ROUND((fm.keyword_count / a.actor_count::numeric), 2)
    END AS keyword_per_actor_ratio
FROM FilteredMovies fm
JOIN ActorMovieCounts a ON fm.movie_title = (SELECT title FROM aka_title WHERE id = a.movie_id LIMIT 1)
LEFT JOIN CompaniesWithMovies cm ON fm.movie_title = (SELECT title FROM aka_title WHERE id = cm.movie_id LIMIT 1)
ORDER BY fm.production_year DESC, fm.keyword_count DESC
LIMIT 10;
