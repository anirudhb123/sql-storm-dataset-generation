WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        num_companies
    FROM 
        MovieDetails
    WHERE 
        rank <= 5
),
KeywordCount AS (
    SELECT 
        t.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    COALESCE(kc.keyword_total, 0) AS total_keywords,
    CASE 
        WHEN kc.keyword_total IS NULL THEN 'No Keywords'
        ELSE 'Keywords Present'
    END AS keyword_status
FROM 
    TopMovies tm
LEFT JOIN 
    KeywordCount kc ON tm.title = (SELECT title FROM aka_title WHERE id = kc.movie_id)
ORDER BY 
    tm.production_year DESC, tm.num_companies DESC;
