WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        COALESCE(cast_person.name, 'Unknown') AS main_actor,
        COUNT(ci.id) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name cast_person ON ci.person_id = cast_person.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword, cast_person.name
),
KeywordStats AS (
    SELECT 
        movie_id, 
        COUNT(DISTINCT movie_keyword) AS unique_keywords,
        MAX(production_year) AS latest_year
    FROM 
        RankedMovies
    GROUP BY 
        movie_id
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        ks.unique_keywords,
        rm.main_actor,
        rm.total_cast,
        CASE 
            WHEN ks.latest_year IS NULL THEN 'No Keywords'
            ELSE 'Has Keywords'
        END AS keyword_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordStats ks ON rm.movie_id = ks.movie_id
)
SELECT 
    fb.movie_id,
    fb.movie_title,
    fb.production_year,
    fb.unique_keywords,
    fb.main_actor,
    fb.total_cast,
    fb.keyword_status
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC, fb.total_cast DESC, fb.unique_keywords ASC
LIMIT 100;
