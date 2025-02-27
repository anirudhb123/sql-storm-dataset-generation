WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
RecentMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        GROUP_CONCAT(ka.name) AS actors, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RecentMovies rm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id IN (SELECT id FROM aka_title WHERE title = rm.title)
    LEFT JOIN 
        aka_name ka ON cc.subject_id = ka.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id IN (SELECT id FROM aka_title WHERE title = rm.title)
    GROUP BY 
        rm.title, rm.production_year
)
SELECT 
    md.title, 
    md.production_year, 
    md.actors, 
    md.company_count, 
    COALESCE(NULLIF(md.company_count, 0), 'No Companies') AS company_info
FROM 
    MovieDetails md
WHERE 
    md.production_year >= (SELECT MAX(production_year) FROM aka_title WHERE production_year IS NOT NULL) - 5
ORDER BY 
    md.production_year DESC, 
    md.title;
