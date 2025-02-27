WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
DetailedCastInfo AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT c.person_id) AS num_actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
FinalBenchmark AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.movie_keyword,
        dci.actors,
        dci.num_actors
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DetailedCastInfo dci ON rm.movie_title = (SELECT title FROM aka_title WHERE id = dci.movie_id)
    WHERE 
        rm.rank = 1
)
SELECT 
    fb.movie_title,
    fb.production_year,
    fb.movie_keyword,
    fb.actors,
    fb.num_actors
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC, fb.movie_title;
