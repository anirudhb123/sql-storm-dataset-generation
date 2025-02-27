WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),

TopActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(c.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(c.movie_id) > 5
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),

MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    t.title AS Movie_Title,
    t.production_year AS Release_Year,
    ra.name AS Actor_Name,
    cs.companies AS Production_Companies,
    mk.keywords AS Related_Keywords
FROM 
    RankedTitles t
LEFT JOIN 
    TopActors ra ON ra.actor_rank <= 5
LEFT JOIN 
    CompanyStats cs ON cs.movie_id = t.title_id
LEFT JOIN 
    MoviesWithKeywords mk ON mk.movie_id = t.title_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND (t.title LIKE '%Action%' OR t.title LIKE '%Adventure%')
    AND COALESCE(cs.company_count, 0) > 0
ORDER BY 
    t.production_year DESC, 
    t.title;

This SQL query uses Common Table Expressions (CTEs) to modularize the query into several logical parts:

1. **RankedTitles**: Ranks titles by production year.
2. **TopActors**: Filters actors with more than five movies and assigns a rank based on their film count.
3. **CompanyStats**: Aggregates the names of production companies per movie.
4. **MoviesWithKeywords**: Aggregates keywords associated with each movie.

The main select statement retrieves relevant movie details, actor names, production companies, and keywords while filtering for movies released between the years 2000 and 2020, that have 'Action' or 'Adventure' in their title, and ensures there are associated companies. 

This complexity showcases various SQL constructs such as CTEs, window functions, string aggregation, and various joins, while also demonstrating performance benchmarking capabilities focusing on multiple relationships between the dataset's entities.
