WITH RecursiveMovieLinks AS (
    SELECT 
        ml1.movie_id,
        ml1.linked_movie_id,
        1 AS link_level
    FROM movie_link ml1
    WHERE ml1.link_type_id = (SELECT id FROM link_type WHERE link = 'Related')

    UNION ALL

    SELECT 
        ml2.movie_id,
        ml2.linked_movie_id,
        rml.link_level + 1
    FROM movie_link ml2
    JOIN RecursiveMovieLinks rml ON rml.linked_movie_id = ml2.movie_id
    WHERE ml2.link_type_id = (SELECT id FROM link_type WHERE link = 'Related')
),
FilteredMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year IS NOT NULL 
        AND t.production_year BETWEEN 2000 AND 2023 
    GROUP BY t.id, t.title, t.production_year
    HAVING COUNT(DISTINCT mc.company_id) > 1
),
TopMovies AS (
    SELECT 
        movie_id, 
        title,
        production_year,
        company_count,
        ROW_NUMBER() OVER (ORDER BY company_count DESC) AS rn
    FROM FilteredMovies
    WHERE company_count IS NOT NULL
),
ActorsInTopMovies AS (
    SELECT 
        t.movie_id,
        ak.name AS actor_name,
        COUNT(ci.role_id) AS role_count,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_note_count
    FROM TopMovies t
    JOIN cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY t.movie_id, ak.name
)
SELECT 
    t.movie_id,
    t.title,
    STRING_AGG(DISTINCT a.actor_name || ' (' || a.role_count || ' roles, Null notes: ' || a.null_note_count || ')', '; ') AS actor_details,
    'Production Companies: ' || t.companies AS company_info,
    (SELECT COUNT(*) 
     FROM RecursiveMovieLinks rml 
     WHERE rml.movie_id = t.movie_id) AS related_movie_count
FROM TopMovies t
LEFT JOIN ActorsInTopMovies a ON t.movie_id = a.movie_id
GROUP BY t.movie_id, t.title, t.companies
ORDER BY t.production_year DESC, related_movie_count DESC
LIMIT 10;
