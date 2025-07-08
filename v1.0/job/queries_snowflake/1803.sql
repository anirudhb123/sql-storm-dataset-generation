
WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
), 
TopRankedMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 3
), 
AverageCompanyTypeCount AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT ct.kind) AS company_type_count
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    tr.title, 
    tr.production_year, 
    ac.actor_count, 
    COALESCE(a.company_type_count, 0) AS company_type_count,
    CASE 
        WHEN ac.actor_count >= 10 THEN 'High'
        WHEN ac.actor_count BETWEEN 5 AND 9 THEN 'Medium'
        ELSE 'Low'
    END AS actor_density,
    LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    TopRankedMovies tr
JOIN 
    RankedMovies ac ON tr.title = ac.title AND tr.production_year = ac.production_year
LEFT JOIN 
    movie_keyword mk ON tr.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    AverageCompanyTypeCount a ON tr.title = (SELECT title FROM aka_title WHERE id = a.movie_id)
GROUP BY 
    tr.title, tr.production_year, ac.actor_count, a.company_type_count
ORDER BY 
    tr.production_year DESC, ac.actor_count DESC;
