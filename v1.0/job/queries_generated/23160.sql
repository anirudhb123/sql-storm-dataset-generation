WITH RecursiveMovieData AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.note AS role_note,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank,
        COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY t.id) AS companies_involved
    FROM
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
        AND (c.note IS NOT NULL OR a.name IS NOT NULL)
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        role_note,
        actor_rank,
        movie_keyword,
        companies_involved
    FROM 
        RecursiveMovieData
    WHERE 
        actor_rank <= 3
        AND (movie_keyword != 'No Keyword' OR role_note IS NULL)
),
FinalOutput AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actor_names,
        COUNT(DISTINCT actor_name) AS actor_count,
        SUM(companies_involved) AS total_companies
    FROM 
        FilteredMovies
    GROUP BY 
        movie_title, production_year
)
SELECT 
    fo.movie_title,
    fo.production_year,
    fo.actor_names,
    fo.actor_count,
    COALESCE(fo.total_companies, 0) AS total_companies,
    CASE 
        WHEN fo.actor_count > 5 THEN 'Star-Studded'
        ELSE 'Niche'
    END AS movie_type
FROM 
    FinalOutput fo
ORDER BY 
    production_year DESC, 
    actor_count DESC NULLS LAST;

-- The query captures:
-- 1. Movies produced since 2000, filtering actors and handling NULL logic for roles.
-- 2. It incorporates a recursive CTE to aggregate actor information based on their roles.
-- 3. It allows for transparent keyword handling and identifies companies involved in each movie.
-- 4. The final selection classifies movies based on the number of actors, thereby introducing an interesting categorization.
