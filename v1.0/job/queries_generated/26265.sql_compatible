
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.title, a.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT p.info || ': ' || p.note, ', ') AS person_info_details,
        c.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS companies_involved
    FROM 
        TopMovies tm
    JOIN 
        title t ON tm.movie_title = t.title AND tm.production_year = t.production_year
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        person_info p ON p.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = t.id)
    GROUP BY 
        t.title, t.production_year, c.kind
)
SELECT 
    md.movie_title,
    md.production_year,
    tm.movie_keyword,
    tm.actor_count,
    md.person_info_details,
    md.company_type,
    md.companies_involved
FROM 
    TopMovies tm
INNER JOIN 
    MovieDetails md ON tm.movie_title = md.movie_title AND tm.production_year = md.production_year
ORDER BY 
    md.production_year DESC, 
    tm.actor_count DESC;
