WITH RecursiveMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(t.production_year, NULL) AS production_year,
        COUNT(c.person_id) OVER (PARTITION BY t.id) AS total_cast,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC NULLS LAST) AS rn
    FROM
        aka_title AS t
    LEFT JOIN
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info AS c ON c.movie_id = cc.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
KeywordUsage AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON k.id = mk.keyword_id
    JOIN 
        title AS m ON m.id = mk.movie_id
    GROUP BY 
        m.movie_id
),
CastedActors AS (
    SELECT 
        c.movie_id,
        a.name,
        a.id AS actor_id
    FROM
        cast_info AS c
    JOIN 
        aka_name AS a ON a.person_id = c.person_id
    WHERE 
        c.nr_order IS NOT NULL
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ku.all_keywords, 'No keywords') AS keywords,
        COUNT(DISTINCT ca.actor_id) AS unique_cast_count,
        (SELECT 
            COUNT(*) 
         FROM 
            movie_companies mc 
         WHERE 
            mc.movie_id = rm.movie_id AND mc.company_type_id = 1) AS production_company_count
    FROM 
        RecursiveMovies AS rm
    LEFT JOIN 
        KeywordUsage AS ku ON ku.movie_id = rm.movie_id
    LEFT JOIN 
        CastedActors AS ca ON ca.movie_id = rm.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ku.all_keywords
)
SELECT 
    movie_id,
    title,
    production_year,
    keywords,
    unique_cast_count,
    production_company_count
FROM 
    FinalResults
WHERE 
    production_year > 2000
    AND unique_cast_count < (SELECT AVG(unique_cast_count) FROM FinalResults)
ORDER BY 
    production_year DESC, unique_cast_count ASC
LIMIT 10;

-- The above SQL query performs the following:
-- 1. It creates several CTEs:
--    - RecursiveMovies: Retrieves movies with their production year and total cast count.
--    - KeywordUsage: Aggregates keywords for each movie in a single comma-separated string.
--    - CastedActors: Gathers actor names for all cast members in movies.
--    - FinalResults: Combines data from the previous CTEs and calculates unique cast counts and production company counts.
-- 2. The final selection filters movies produced after 2000 with fewer than the average unique cast count and orders the results.
