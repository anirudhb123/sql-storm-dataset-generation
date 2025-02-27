WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT m.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count, 
        company_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.company_count,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = a.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') 
     AND mi.info IS NOT NULL) AS budget_entry_count,
    STRING_AGG(DISTINCT c.name, ', ') AS companies 
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
LEFT JOIN 
    company_name c ON mc.company_id = c.id
GROUP BY 
    tm.title, tm.production_year, tm.actor_count, tm.company_count
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
