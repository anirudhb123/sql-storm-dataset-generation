WITH RankedTitles AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
RecentTitles AS (
    SELECT 
        actor_id,
        actor_name,
        movie_title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        rank <= 3
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT gt.kind, ', ') AS genres
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title mt ON mc.movie_id = mt.id
    JOIN 
        kind_type gt ON mt.kind_id = gt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    COALESCE(mg.genres, 'Unknown') AS genres,
    COUNT(DISTINCT mc.company_id) AS number_of_companies
FROM 
    RecentTitles rt
LEFT JOIN 
    movie_companies mc ON rt.production_year = mc.movie_id
LEFT JOIN 
    MovieGenres mg ON mc.movie_id = mg.movie_id
WHERE 
    rt.production_year > 2000
GROUP BY 
    rt.actor_name, rt.movie_title, rt.production_year, mg.genres
ORDER BY 
    rt.actor_name, rt.production_year DESC;
