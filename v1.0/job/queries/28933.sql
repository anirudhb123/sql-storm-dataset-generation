
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.num_companies,
        ac.num_actors,
        rm.company_names,
        rm.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCount ac ON rm.movie_id = ac.movie_id
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.num_companies,
    fb.num_actors,
    fb.company_names,
    fb.keywords
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.num_actors DESC, fb.num_companies DESC
LIMIT 10;
