
WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.actor_count,
        STRING_AGG(DISTINCT an.name, ', ' ORDER BY an.name) AS actors,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id) 
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.title, tm.actor_count
)
SELECT 
    md.title,
    md.actor_count,
    COALESCE(md.actors, 'No actors') AS actors,
    COALESCE(md.companies, 'No companies') AS companies
FROM 
    MovieDetails md
ORDER BY 
    md.actor_count DESC;
