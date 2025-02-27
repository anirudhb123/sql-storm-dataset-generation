WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
LatestTitles AS (
    SELECT 
        actor_name,
        movie_title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        rn = 1
),
MovieCompaniesInfo AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT m.id) AS total_movies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, c.name, ct.kind
),
FilteredMovies AS (
    SELECT 
        lt.actor_name,
        lt.movie_title,
        lt.production_year,
        mci.company_name,
        mci.company_type,
        COALESCE(mci.total_movies, 0) AS total_movies
    FROM 
        LatestTitles lt
    LEFT JOIN 
        MovieCompaniesInfo mci ON lt.production_year = mci.movie_id
)

SELECT 
    actor_name,
    movie_title,
    production_year,
    company_name,
    company_type,
    CASE 
        WHEN total_movies > 0 THEN 'Has Company'
        ELSE 'No Company'
    END AS company_status,
    CASE 
        WHEN movie_title IS NULL THEN 'Unknown Title'
        WHEN movie_title LIKE '%The%' THEN 'Contains The'
        ELSE 'Regular Title'
    END AS title_category
FROM 
    FilteredMovies
WHERE 
    (production_year BETWEEN 2000 AND 2023 OR production_year IS NULL)
    AND (company_type != 'Unknown' OR company_type IS NULL)
ORDER BY 
    actor_name, production_year DESC;

-- Additional statistical analysis
WITH ActorStats AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count,
        AVG(COALESCE(production_year, 2023)) AS avg_production_year,
        STRING_AGG(DISTINCT company_name, ', ') AS company_list
    FROM 
        FilteredMovies 
    GROUP BY 
        actor_name
)

SELECT 
    *,
    CASE 
        WHEN movie_count > 5 THEN 'Prolific Actor'
        ELSE 'Less Active Actor'
    END AS activity_level
FROM 
    ActorStats
ORDER BY 
    avg_production_year DESC;
