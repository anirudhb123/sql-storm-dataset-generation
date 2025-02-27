WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
DistinctCharacterCount AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT actor_name) AS distinct_actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_title, production_year
),
KeywordStatistics AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.title
),
MovieStatistics AS (
    SELECT 
        m.movie_title,
        m.production_year,
        m.distinct_actor_count,
        k.keyword_count
    FROM 
        DistinctCharacterCount m
    LEFT JOIN 
        KeywordStatistics k ON m.movie_title = k.movie_title
)
SELECT 
    ms.movie_title,
    ms.production_year,
    ms.distinct_actor_count,
    COALESCE(ms.keyword_count, 0) AS keyword_count
FROM 
    MovieStatistics ms
ORDER BY 
    ms.production_year DESC,
    ms.distinct_actor_count DESC;
