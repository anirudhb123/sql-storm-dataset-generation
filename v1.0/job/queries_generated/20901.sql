WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role,
        COALESCE(avg(r.role_number), 0) AS avg_role_order,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN aka_name a ON a.person_id IN (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = t.id
    )
    JOIN comp_cast_type c ON c.id = (
        SELECT ci.person_role_id 
        FROM cast_info ci 
        WHERE ci.movie_id = t.id AND ci.person_id = a.person_id
        LIMIT 1
    )
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(nr_order) AS role_number
        FROM cast_info 
        GROUP BY movie_id
    ) r ON r.movie_id = t.id
    WHERE t.production_year IS NOT NULL 
        AND t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.id, t.title, t.production_year, a.name, c.kind
), RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY avg_role_order DESC, movie_title) AS rank
    FROM MovieDetails
), PopularMovies AS (
    SELECT 
        *,
        CASE 
            WHEN keyword_count > 5 THEN 'Popular'
            WHEN keyword_count BETWEEN 3 AND 5 THEN 'Moderate'
            ELSE 'Less Popular' 
        END AS popularity_rating
    FROM RankedMovies
)
SELECT 
    pm.movie_title,
    pm.production_year,
    pm.actor_name,
    pm.role,
    pm.avg_role_order,
    pm.keywords_count,
    pm.company_count,
    pm.rank,
    pm.popularity_rating
FROM PopularMovies pm
WHERE pm.rank <= 10
    AND (pm.company_count IS NULL OR pm.company_count > 2)
    AND (pm.popularity_rating = 'Popular' OR (pm.role = 'Lead' AND pm.keywords_count = 0))
ORDER BY pm.production_year DESC, pm.rank;
