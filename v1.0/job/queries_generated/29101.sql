WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordCount AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT keywords) AS keyword_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_title
),
FinalBenchmark AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_names,
        rm.keywords,
        rm.company_count,
        kc.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        KeywordCount kc ON rm.movie_title = kc.movie_title
    WHERE 
        rm.company_count > 2
    ORDER BY 
        rm.production_year DESC, kc.keyword_count DESC
)
SELECT 
    movie_title,
    production_year,
    actor_names,
    keywords,
    company_count,
    keyword_count
FROM 
    FinalBenchmark
LIMIT 50;
