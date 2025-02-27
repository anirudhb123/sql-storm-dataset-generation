WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.company_id) DESC) AS rnk
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rnk <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ki.keyword_count, 0) AS keyword_count,
    COALESCE(pi.actor_count, 0) AS actor_count,
    CASE 
        WHEN tm.production_year >= 2000 THEN 'Recent'
        ELSE 'Classic'
    END AS movie_age_group
FROM 
    TopMovies tm
LEFT JOIN (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
) ki ON tm.title = (SELECT title FROM aka_title WHERE id = ki.movie_id)
LEFT JOIN (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) pi ON tm.title = (SELECT title FROM aka_title WHERE id = pi.movie_id)
WHERE 
    tm.production_year BETWEEN 1990 AND 2023
ORDER BY 
    tm.production_year DESC;
