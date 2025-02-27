WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
ActorsWithTitles AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS rn_actor
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
),
CombinedData AS (
    SELECT 
        a.actor_name,
        m.movie_title,
        m.production_year,
        COALESCE(NULLIF(m.production_year, 0), 'Unknown') AS year_display,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS movie_era
    FROM 
        ActorsWithTitles a
    JOIN 
        RankedMovies m ON a.movie_title = m.title AND a.production_year = m.production_year
    WHERE 
        a.rn_actor = 1
)
SELECT 
    c.actor_name, 
    c.movie_title, 
    c.year_display, 
    c.movie_era,
    COALESCE(ki.keyword, 'No Keywords') AS keyword_info
FROM 
    CombinedData c
LEFT JOIN 
    movie_keyword mk ON c.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
WHERE 
    c.production_year IS NOT NULL
ORDER BY 
    c.movie_era, c.year_display, c.actor_name;
