WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM CURRENT_DATE) - t.production_year 
                           ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_movie_year,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS c ON a.person_id = c.person_id
    JOIN 
        aka_title AS t ON c.movie_id = t.id
    LEFT JOIN 
        RankedMovies AS m ON t.id = m.movie_id
    GROUP BY 
        a.person_id, a.name
),
CompanyStatistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        AVG(co.name_pcode_nf IS NOT NULL)::FLOAT AS avg_non_null_pcode
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        am.actor_name,
        am.movie_count,
        am.avg_movie_year,
        cs.company_count,
        cs.avg_non_null_pcode
    FROM 
        ActorMovieInfo AS am
    LEFT JOIN 
        CompanyStatistics AS cs ON am.movie_count = cs.company_count OR am.movie_count = 0
    WHERE 
        am.movie_count > 0 AND 
        (am.avg_movie_year IS NOT NULL AND am.avg_movie_year < EXTRACT(YEAR FROM CURRENT_DATE) - 20)
)
SELECT 
    actor_name,
    movie_count,
    avg_movie_year,
    COALESCE(company_count, 0) AS number_of_companies,
    round(avg_non_null_pcode * 100, 2) AS percentage_non_null_pcode
FROM 
    FinalResults
ORDER BY 
    movie_count DESC, 
    avg_movie_year ASC
LIMIT 100;

-- This query aims to benchmark performance by fetching actors with a certain number of movies,
-- while also calculating related statistics about the companies involved in the movies, 
-- including strange conditions that may produce NULLs, alongside complex aggregations and rankings.
