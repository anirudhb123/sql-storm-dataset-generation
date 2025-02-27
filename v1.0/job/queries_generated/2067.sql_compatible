
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id, 
        a.title, 
        a.production_year, 
        COUNT(mc.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(mc.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        company_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id, 
        tm.title, 
        tm.production_year, 
        COALESCE(ka.name, 'Unknown') AS actor_name,
        ka.id AS actor_id,
        COUNT(mk.id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ka ON cc.subject_id = ka.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, ka.name, ka.id
),
FinalResults AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        STRING_AGG(DISTINCT md.actor_name, ', ') AS actors,
        SUM(md.keyword_count) AS keyword_count
    FROM 
        MovieDetails md
    WHERE 
        md.keyword_count > 0
    GROUP BY 
        md.movie_id, md.title, md.production_year
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actors,
    fr.keyword_count
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.keyword_count DESC;
