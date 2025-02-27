WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MIN(t.production_year) AS first_movie_year,
        MAX(t.production_year) AS last_movie_year
    FROM cast_info c
    JOIN aka_name a ON a.person_id = c.person_id
    JOIN aka_title t ON t.id = c.movie_id
    GROUP BY c.person_id
),
TopActors AS (
    SELECT 
        a.person_id,
        a.movie_count,
        a.first_movie_year,
        a.last_movie_year,
        RANK() OVER (ORDER BY a.movie_count DESC) AS actor_rank
    FROM ActorMovieCount a
    WHERE a.movie_count > 5
),
CompanyMovieCount AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name c ON c.id = mc.company_id
    GROUP BY mc.company_id
),
FilteredCompanies AS (
    SELECT 
        cm.company_id,
        cm.total_movies,
        cm.company_names
    FROM CompanyMovieCount cm
    WHERE cm.total_movies > (SELECT AVG(total_movies) FROM CompanyMovieCount)
),
TheatreMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COUNT(DISTINCT c.id) AS cast_size
    FROM title t
    LEFT JOIN cast_info c ON c.movie_id = t.id
    WHERE t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Theatre%')
    GROUP BY t.id
)
SELECT 
    ta.person_id,
    (SELECT COUNT(DISTINCT c.movie_id) 
     FROM cast_info c 
     WHERE c.person_id = ta.person_id) AS all_movies_count,
    ta.first_movie_year,
    ta.last_movie_year,
    ra.title,
    ra.production_year,
    COALESCE(cm.company_names, 'No Companies') AS company_involvement,
    tm.cast_size
FROM TopActors ta
JOIN RankedTitles ra ON ra.title_rank <= 3
LEFT JOIN FilteredCompanies cm ON cm.company_id IN (SELECT mc.company_id FROM movie_companies mc WHERE mc.movie_id = ra.title_id)
LEFT JOIN TheatreMovies tm ON tm.title_id = ra.title_id
WHERE 
    COALESCE(ta.movie_count, 0) > 5 AND 
    (ra.production_year IS NOT NULL OR tm.cast_size > 0)
ORDER BY ta.movie_count DESC, ra.production_year DESC;
