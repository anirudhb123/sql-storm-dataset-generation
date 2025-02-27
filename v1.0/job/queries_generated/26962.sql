WITH MovieActors AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(c.id) AS cast_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        a.name, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        SUM(cast_count) AS total_cast
    FROM 
        MovieActors
    GROUP BY 
        movie_title, production_year
    ORDER BY 
        total_cast DESC
    LIMIT 10
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    GROUP_CONCAT(DISTINCT company.company_name) AS production_companies,
    GROUP_CONCAT(DISTINCT company.company_type) AS company_types,
    ta.actor_name,
    ta.cast_count
FROM 
    TopMovies tm
JOIN 
    MovieActors ta ON tm.movie_title = ta.movie_title AND tm.production_year = ta.production_year
JOIN 
    CompanyDetails company ON tm.movie_id = company.movie_id
GROUP BY 
    tm.movie_title, tm.production_year, ta.actor_name, ta.cast_count
ORDER BY 
    tm.production_year DESC, tm.movie_title ASC;

This SQL query aggregates data from the `aka_name`, `aka_title`, and `movie_companies` tables to analyze and benchmark string processing related to movie actors, titles, and production companies. It identifies the top 10 movies post-2000 based on the number of cast members, retrieves associated production companies, and presents the findings in a structured format.
