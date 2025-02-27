WITH RankedMovies AS (
    SELECT 
        t.title, 
        a.name AS actor_name, 
        a.surname_pcode, 
        t.production_year, 
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        r.title, 
        r.actor_name, 
        r.production_year,
        mk.keywords,
        COALESCE(COUNT(DISTINCT mc.company_id), 0) AS company_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_companies mc ON r.title = (SELECT title FROM title WHERE id = mc.movie_id)
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = r.title LIMIT 1)
    GROUP BY 
        r.title, r.actor_name, r.production_year, mk.keywords
)
SELECT 
    production_year, 
    COUNT(*) AS movie_count,
    STRING_AGG(title, '; ') AS titles,
    STRING_AGG(DISTINCT actor_name, ', ') AS actors,
    SUM(company_count) AS total_companies,
    STRING_AGG(DISTINCT keywords, '; ') AS aggregated_keywords
FROM 
    DetailedMovieInfo
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
