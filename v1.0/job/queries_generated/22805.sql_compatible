
WITH RecursiveActors AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        ak.name,
        COALESCE(c.companies_count, 0) AS companies_count,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY ak.name) AS rn
    FROM 
        aka_name ak
    JOIN 
        cast_info a ON ak.person_id = a.person_id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(DISTINCT mc.company_id) AS companies_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) c ON a.movie_id = c.movie_id
    WHERE 
        ak.name IS NOT NULL
),

DistinctTitles AS (
    SELECT 
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS year_rank
    FROM 
        aka_title title
    WHERE 
        title.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
        AND title.production_year IS NOT NULL
),

UnpopularActors AS (
    SELECT 
        actor_id,
        SUM(companies_count) AS total_companies
    FROM 
        RecursiveActors
    GROUP BY 
        actor_id
    HAVING 
        SUM(companies_count) < 1
),

ActorsWithMovies AS (
    SELECT 
        ra.actor_id,
        rt.title,
        rt.production_year,
        COUNT(DISTINCT a.movie_id) AS movie_count
    FROM 
        RecursiveActors ra
    JOIN 
        cast_info a ON ra.person_id = a.person_id
    JOIN 
        aka_title rt ON a.movie_id = rt.movie_id
    WHERE 
        a.nr_order = 1
    GROUP BY 
        ra.actor_id, rt.title, rt.production_year
),

Summary AS (
    SELECT 
        u.actor_id,
        COUNT(DISTINCT am.title) AS unique_movies,
        AVG(am.movie_count) AS avg_movies,
        STRING_AGG(DISTINCT am.title, ', ') AS movie_list
    FROM 
        UnpopularActors u
    JOIN 
        ActorsWithMovies am ON u.actor_id = am.actor_id
    GROUP BY 
        u.actor_id
)

SELECT 
    ak.id AS actor_id,
    ak.name AS actor_name,
    s.unique_movies,
    s.avg_movies,
    s.movie_list,
    CASE 
        WHEN s.unique_movies = 0 THEN 'No Movies'
        WHEN s.unique_movies > 0 AND s.avg_movies > 1 THEN 'Frequent Actor'
        ELSE 'Occasional Actor'
    END AS actor_category
FROM 
    aka_name ak
JOIN 
    Summary s ON ak.id = s.actor_id
LEFT JOIN 
    cast_info ci ON ci.person_id = ak.person_id
LEFT JOIN 
    aka_title t ON t.movie_id = ci.movie_id
WHERE 
    t.title IS NOT NULL OR s.unique_movies IS NULL
ORDER BY 
    CASE 
        WHEN s.unique_movies = 0 THEN 1
        ELSE 0
    END,
    ak.name;
