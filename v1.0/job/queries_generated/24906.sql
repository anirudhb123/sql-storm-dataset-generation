WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.kind_id ORDER BY title.production_year DESC) AS rn
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        aka_name.person_id,
        COUNT(DISTINCT aka_title.id) AS movie_count,
        MAX(aka_title.production_year) AS latest_movie_year
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    JOIN 
        aka_title ON cast_info.movie_id = aka_title.id
    GROUP BY 
        aka_name.person_id
    HAVING 
        COUNT(DISTINCT aka_title.id) > 5
),
MoviesByCompany AS (
    SELECT
        movie_companies.movie_id,
        STRING_AGG(DISTINCT company_name.name, ', ') AS companies
    FROM 
        movie_companies
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    GROUP BY 
        movie_companies.movie_id
),
ComplexJoin AS (
    SELECT 
        m.title AS movie_title,
        a.name AS actor_name,
        c.observable_property,
        RANK() OVER (PARTITION BY m.id ORDER BY COALESCE(c.observable_property, 'N/A') DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        (SELECT 
            movie_id,
            SUM(CASE WHEN note IS NULL THEN 1 ELSE 0 END) AS observable_property
         FROM 
            movie_info
         GROUP BY 
            movie_id) c ON c.movie_id = m.id
),
TheaterPerformance AS (
    SELECT 
        mt.movie_title,
        mt.actor_name,
        COALESCE(mp.companies, 'Independent') AS production_companies,
        mt.rank
    FROM 
        ComplexJoin mt
    LEFT JOIN 
        MoviesByCompany mp ON mt.movie_title = mp.movie_title
    WHERE 
        mt.rank < 5
)
SELECT 
    tp.movie_title,
    tp.actor_name,
    tp.production_companies,
    COALESCE(rt.title, 'N/A') AS recommended_title
FROM 
    TheaterPerformance tp
LEFT JOIN 
    RankedTitles rt ON tp.movie_title = rt.title
WHERE 
    rt.rn = 1
ORDER BY 
    tp.movie_title ASC, 
    tp.actor_name DESC;
