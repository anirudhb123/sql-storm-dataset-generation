WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM aka_title a
    JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE a.production_year >= 2000
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        ac.role_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.movie_id) AS total_movies
    FROM aka_name ak
    JOIN cast_info ac ON ak.person_id = ac.person_id
    JOIN aka_title a ON ac.movie_id = a.id
    LEFT JOIN complete_cast c ON c.movie_id = a.id AND c.subject_id = ak.id
    GROUP BY ak.name, ac.role_id, a.title, a.production_year
),
TopActors AS (
    SELECT 
        actor_name, 
        total_movies, 
        RANK() OVER (ORDER BY total_movies DESC) AS actor_rank
    FROM ActorRoles
    WHERE role_id IN (SELECT id FROM role_type WHERE role LIKE '%lead%')
)
SELECT 
    rm.title,
    rm.production_year,
    ta.actor_name,
    ta.total_movies,
    CASE 
        WHEN rm.company_name IS NULL THEN 'Unknown Company'
        ELSE rm.company_name
    END AS effective_company,
    COALESCE(ta.actor_rank, 'No Rank') AS actor_rank
FROM RankedMovies rm
JOIN TopActors ta ON rm.title = ta.title
WHERE rm.rn <= 5
ORDER BY rm.production_year DESC, ta.total_movies DESC;
