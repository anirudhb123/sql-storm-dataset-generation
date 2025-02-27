WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS companies,
        COUNT(DISTINCT c1.company_id) AS company_count
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        company_name c1 ON mc.company_id = c1.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        actors,
        keywords,
        companies,
        company_count,
        RANK() OVER (ORDER BY production_year DESC, company_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    rank,
    movie_title,
    production_year,
    actors,
    keywords,
    companies,
    company_count
FROM 
    RankedMovies
WHERE 
    rank <= 10
ORDER BY 
    rank;

This SQL query performs the following:

1. It defines a common table expression (CTE) called `MovieDetails` to gather an extensive set of information about movies, including their titles, production years, actors, keywords, and companies involved.
2. It uses various joins to access all related tables, ensuring that the results accurately reflect distinct actors, keywords, and companies for each movie.
3. The `STRING_AGG` function consolidates actor names and keywords into comma-separated strings to present coherent lists.
4. A second CTE, `RankedMovies`, ranks the movies based on their production year and the count of companies involved.
5. Finally, it selects the top 10 movies based on this ranking, ensuring that the final output presents a clear, ordered list of movies with their details.
