WITH RecursiveActor AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY c.person_id) AS total_movies,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS latest_movie_row
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE a.name IS NOT NULL
),
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id
),
FilteredActors AS (
    SELECT 
        ra.*,
        md.movie_title,
        md.production_year,
        md.keywords
    FROM RecursiveActor ra
    LEFT JOIN MovieDetails md ON ra.latest_movie_row = 1 AND ra.total_movies > 2 
)

SELECT 
    fa.actor_name,
    fa.total_movies,
    COALESCE(fa.movie_title, 'No Movies') AS latest_movie,
    COALESCE(fa.production_year, 'N/A') AS latest_movie_year,
    CASE 
        WHEN fa.keywords IS NOT NULL THEN fa.keywords
        ELSE 'No Keywords'
    END AS movie_keywords
FROM FilteredActors fa
WHERE fa.total_movies > 1
ORDER BY fa.total_movies DESC, fa.actor_name;

-- Additional complexity with complicated predicates and outer joins
WITH ActorStats AS (
    SELECT
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) * 100 AS note_percentage
    FROM cast_info c
    GROUP BY c.person_id
)

SELECT *
FROM ActorStats a
FULL OUTER JOIN aka_name an ON a.person_id = an.person_id
WHERE a.note_percentage > 50 
    OR (an.name IS NOT NULL AND an.name NOT LIKE '%Unknown%')
ORDER BY a.movie_count DESC;

-- Using NULL logic and permissions from other tables for filtering:
WITH QualifiedActors AS (
    SELECT 
        DISTINCT a.person_id,
        a.name
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    WHERE a.md5sum IS NOT NULL OR a.name_pcode_cf IS NULL
),
MoviesWithReviews AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(mr.id) AS review_count
    FROM aka_title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    LEFT JOIN movie_info_idx mr ON mi.id = mr.movie_id
    GROUP BY t.id
)

SELECT 
    qa.name AS actor_name,
    mw.title AS movie_title,
    mw.review_count
FROM QualifiedActors qa
LEFT JOIN MoviesWithReviews mw ON qa.person_id IN (
    SELECT person_id
    FROM cast_info
    WHERE movie_id = mw.movie_id
)
ORDER BY mw.review_count DESC NULLS LAST;
