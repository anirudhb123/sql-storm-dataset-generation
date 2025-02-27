WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) as movie_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
        AVG(m.production_year) AS avg_production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title m ON ci.movie_id = m.id
    GROUP BY 
        c.person_id
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT com.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name com ON mc.company_id = com.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    r.title,
    r.production_year,
    a.total_movies,
    a.notes_count,
    a.avg_production_year,
    COALESCE(cmc.company_count, 0) AS company_count
FROM 
    RankedMovies r
LEFT JOIN 
    ActorStats a ON r.rn = 1 AND r.production_year = a.avg_production_year
LEFT JOIN 
    CompanyMovieCount cmc ON r.title = (SELECT title FROM aka_title WHERE id = cmc.movie_id LIMIT 1)
WHERE 
    r.movie_count > 2
    AND (a.total_movies IS NULL OR a.notes_count > 0)
ORDER BY 
    r.production_year DESC, a.total_movies DESC;

-- Special logic to handle NULL conditions in subqueries
WITH NullHandled AS (
    SELECT 
        CASE 
            WHEN (SELECT COUNT(*) FROM actor_stats) > 0 THEN 'Data Available' 
            ELSE 'No Actors Present' 
        END AS actor_data_status,
        COUNT(DISTINCT m.id) AS total_movies,
        COALESCE(MAX(m.production_year), 0) AS last_movie_year
    FROM 
        aka_title m
    WHERE 
        m.phonetic_code IS NOT NULL
        OR (m.title IS NULL AND m.production_year IS NOT NULL)
    GROUP BY 
        CASE WHEN EXISTS (SELECT 1 FROM aka_title WHERE title IS NULL) THEN 'Contains Null Titles' ELSE 'All Titles Present' END
)
SELECT 
    *
FROM 
    NullHandled
WHERE 
    actor_data_status = 'Data Available'
    AND last_movie_year > 2000
ORDER BY 
    total_movies DESC;
