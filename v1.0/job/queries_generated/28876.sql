WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name a ON cc.subject_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        md.keywords,
        md.actors,
        LENGTH(md.title) AS title_length,
        LENGTH(md.keywords) AS keyword_count
    FROM 
        MovieDetails md
    WHERE 
        md.company_name IS NOT NULL AND 
        LENGTH(md.actors) > 0
)
SELECT 
    DISTINCT company_name,
    COUNT(movie_id) AS total_movies,
    AVG(title_length) AS avg_title_length,
    SUM(keyword_count) AS total_keywords
FROM 
    FilteredMovies
GROUP BY 
    company_name
ORDER BY 
    total_movies DESC, avg_title_length DESC;
