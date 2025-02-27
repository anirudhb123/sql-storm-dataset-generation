WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title ASC) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ci.nr_order = 1
    GROUP BY 
        ak.name 
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
RecentMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.info, 'No Info Available') AS info,
        mt.released_date
    FROM 
        (SELECT title.*, mi.info AS info, m.released_date AS released_date
            FROM title 
            LEFT JOIN movie_info mi ON title.id = mi.movie_id
            LEFT JOIN movie_companies m ON title.id = m.movie_id
            WHERE m.company_type_id = 1 AND title.production_year >= 2020) mt
)
SELECT 
    r.title,
    r.production_year,
    COALESCE(ta.actor_name, 'No Leading Actor') AS leading_actor,
    COUNT(DISTINCT m.keyword) AS keyword_count,
    STRING_AGG(m.keyword, ', ') AS keywords
FROM 
    RankedTitles r
LEFT JOIN 
    TopActors ta ON r.title = ta.actor_name
LEFT JOIN 
    movie_keyword mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    keyword m ON mk.keyword_id = m.id
RIGHT JOIN 
    RecentMovies rm ON r.id = rm.movie_id
WHERE 
    rm.production_year >= 2021 OR rm.released_date IS NULL
GROUP BY 
    r.title, r.production_year, ta.actor_name
ORDER BY 
    r.production_year DESC, r.title;
