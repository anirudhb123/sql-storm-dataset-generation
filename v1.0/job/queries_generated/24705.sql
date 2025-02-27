WITH RecursiveActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM  
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
    AND 
        a.name NOT LIKE '%Test%'
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(title_id) AS movie_count
    FROM 
        RecursiveActorMovies
    GROUP BY 
        actor_id, actor_name
    HAVING 
        COUNT(title_id) > 3
),
RecentTitles AS (
    SELECT 
        title_id,
        title_name,
        production_year
    FROM 
        RecursiveActorMovies
    WHERE 
        movie_rank <= 3
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        k.keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
),
CompanyMovieCount AS (
    SELECT 
        c.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.name
    HAVING 
        total_movies > 1
)
SELECT 
    a.actor_name,
    t.title_name,
    t.production_year,
    kw.keyword,
    c.company_name,
    cc.total_movies,
    COUNT(DISTINCT a.id) OVER (PARTITION BY a.actor_id) AS actor_collab_count
FROM 
    RecentTitles t
JOIN 
    TopActors a ON t.actor_id = a.actor_id
OUTER APPLY (
    SELECT STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        MoviesWithKeywords kw 
    WHERE 
        kw.title_id = t.title_id
) AS kw
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    CompanyMovieCount cc ON c.name = cc.company_name
WHERE 
    (c.country_code IS NULL OR c.country_code <> 'US')
    AND (t.production_year > 2000 OR t.production_year IS NULL)
ORDER BY 
    a.actor_name, t.production_year DESC;

This SQL query is quite complex and incorporates various SQL constructs:

1. **CTEs (Common Table Expressions)** for breaking down the logic into manageable parts:
    - `RecursiveActorMovies` retrieves actors and the titles of their movies, ranking them by production year.
    - `TopActors` filters actors who have acted in more than 3 movies.
    - `RecentTitles` gets the top 3 recent titles for each actor.
    - `MoviesWithKeywords` combines titles with their related keywords.
    - `CompanyMovieCount` counts movies produced by each company.

2. **OUTER APPLY** is used to collect a list of distinct keywords for each title.

3. **LEFT JOINs** to bring in additional data from `movie_companies` and `company_name`, including filtering on NULL values in the country code. 

4. **Calculations and Aggregations** to count collaborations and group results.

5. **WHERE Clauses** with sophisticated predicates to explore NULL values and various conditional logic.

6. **Optional filtering and ordering** that showcase flexibility in handling the dataset.

7. **STRING_AGG**, demonstrating string aggregation across movies with relevant keywords.

This query is designed both for performance benchmarking and for showcasing the ability to handle complex queries in SQL with nuanced requirements.
