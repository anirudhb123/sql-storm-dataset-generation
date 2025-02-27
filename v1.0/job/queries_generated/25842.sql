WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mk.keyword) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
MovieCrew AS (
    SELECT 
        cm.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        complete_cast cc
    JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    JOIN 
        movie_companies mc ON cc.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        cm.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword_count,
    tm.keywords,
    mc.actors,
    mc.companies
FROM 
    TopMovies tm
JOIN 
    MovieCrew mc ON tm.movie_id = mc.movie_id
ORDER BY 
    tm.production_year DESC, tm.keyword_count DESC;
