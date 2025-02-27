WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        m.name AS company_name,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT
        title,
        production_year,
        company_name,
        keyword
    FROM 
        RankedMovies
    WHERE 
        rn = 1
),
CastDetails AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        a.name, t.title, t.production_year
),
FinalBenchmark AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.company_name,
        tm.keyword,
        cd.actor_name,
        cd.cast_count
    FROM 
        TopMovies tm
    JOIN 
        CastDetails cd ON tm.title = cd.title AND tm.production_year = cd.production_year
)

SELECT 
    fb.title,
    fb.production_year,
    fb.company_name,
    fb.keyword,
    fb.actor_name,
    fb.cast_count
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.production_year DESC, fb.title;
