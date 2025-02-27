WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t 
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
),

ActorDetails AS (
    SELECT 
        ka.name AS actor_name,
        ka.person_id,
        COUNT(c.movie_id) AS movies_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_titles
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        RankedMovies t ON c.movie_id = t.movie_id
    GROUP BY 
        ka.name, ka.person_id
    HAVING 
        COUNT(c.movie_id) > 1
),

CompanyInformation AS (
    SELECT 
        c.name AS company_name,
        COUNT(mc.movie_id) AS produced_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    WHERE 
        c.country_code = 'USA'
    GROUP BY 
        c.name
)

SELECT 
    ad.actor_name,
    ad.movies_count,
    ad.movies_titles,
    ci.company_name,
    ci.produced_movies
FROM 
    ActorDetails ad
JOIN 
    CompanyInformation ci ON ad.movies_count = ci.produced_movies
ORDER BY 
    ad.movies_count DESC, ci.produced_movies DESC;

This SQL query benchmarks the processing of strings in a multi-step process, designed to extract useful data about movies, actors, and production companies from the provided schema. It includes several Common Table Expressions (CTEs) to break the process into manageable parts.

1. **RankedMovies**: This CTE selects titles from `aka_title`, filtering for 'Drama' from the genre info and capturing the ranking of each title per production year.

2. **ActorDetails**: Aggregates actors who have appeared in more than one movie, concatenating their movie titles into a single string for detailed insights.

3. **CompanyInformation**: Gathers data on US-based production companies, counting the movies produced by each.

Finally, the main query joins the results of `ActorDetails` and `CompanyInformation` to provide a comprehensive view of actors and the company activity related to them. The entire result is ordered by the number of movies and then company output, optimizing string processing through aggregated results.
