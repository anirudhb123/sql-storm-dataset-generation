WITH RECURSIVE ActorMovies AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        COALESCE(t.title, 'Unknown Title') AS movie_title,
        COALESCE(p.name, 'Unknown Actor') AS actor_name,
        LEAD(COALESCE(t.production_year, 0)) OVER (PARTITION BY ca.person_id ORDER BY t.production_year) AS next_year
    FROM cast_info ca
    LEFT JOIN aka_name p ON ca.person_id = p.person_id
    LEFT JOIN aka_title t ON ca.movie_id = t.movie_id
    WHERE p.name IS NOT NULL
),
MovieStats AS (
    SELECT 
        person_id,
        COUNT(movie_id) AS total_movies,
        COUNT(DISTINCT movie_id) FILTER (WHERE next_year - t.production_year < 5) AS frequent_collaborations
    FROM ActorMovies t
    GROUP BY person_id
),
TopActors AS (
    SELECT 
        person_id,
        total_movies,
        frequent_collaborations,
        RANK() OVER (ORDER BY total_movies DESC, frequent_collaborations DESC) AS actor_rank
    FROM MovieStats
    WHERE total_movies > 1
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT cn.country_code) AS country_count
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    a.actor_name,
    a.movie_title,
    cs.country_count,
    CASE WHEN a.next_year IS NULL THEN 'N/A' ELSE a.next_year::TEXT END AS 'Next Released Year',
    CASE 
        WHEN a.movie_title IS NULL THEN 'No Movies Found'
        ELSE 'Movies Available'
    END AS availability,
    d.companies
FROM ActorMovies a
LEFT JOIN TopActors ta ON a.person_id = ta.person_id
LEFT JOIN CompanyDetails d ON a.movie_id = d.movie_id
LEFT JOIN kind_type kt ON kt.id = (
    SELECT k.id 
    FROM aka_title k 
    WHERE k.title = a.movie_title 
    ORDER BY k.production_year 
    LIMIT 1
)
WHERE ta.actor_rank <= 10 
AND (a.movie_title IS NOT NULL OR a.actor_name IS NOT NULL)
ORDER BY ta.actor_rank, d.country_count DESC NULLS LAST;

This SQL query does the following:
1. It uses a Common Table Expression (CTE) with recursion to compile a list of movies acted in by each person, alongside the next production year.
2. It calculates statistics for actors, like the total number of movies and frequent collaborations.
3. It extracts company information related to movies, including the distinct names of companies and country count.
4. The final SELECT statement gathers all this data, applying various cases and string operations to generate meaningful output while filtering for the top actors based on their movie counts. This includes handling NULL values and implementing unusual SQL behaviors such as the conditional aggregation and nested subqueries.

