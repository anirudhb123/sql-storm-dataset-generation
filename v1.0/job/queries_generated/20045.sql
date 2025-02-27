WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank_per_year
    FROM 
        aka_title t
),

ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),

MoviesWithActor AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        t.title,
        t.production_year,
        m.id AS movie_id
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        aka_title t ON c.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id AND mc.note IS NULL
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year IS NOT NULL
        AND co.country_code IS NOT NULL
)

SELECT 
    ma.name AS actor_name,
    COUNT(DISTINCT mw.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mw.title, '; ') AS titles,
    SUM(CASE WHEN mw.production_year IS NOT NULL THEN 1 ELSE 0 END) AS movies_with_year,
    AVG(year_difference) AS avg_year_difference,
    MAX(year_difference) AS max_year_difference,
    MIN(year_difference) AS min_year_difference
FROM 
    (SELECT 
        a.name,
        mw.*,
        ABS(EXTRACT(YEAR FROM CURRENT_DATE) - mw.production_year) AS year_difference
    FROM 
        MoviesWithActor mw
    INNER JOIN 
        aka_name a ON mw.aka_id = a.id
    ) AS ma
WHERE 
    ma.production_year > (SELECT MAX(t.production_year) FROM RankedTitles t WHERE t.rank_per_year <= 5)
GROUP BY 
    ma.name
HAVING 
    COUNT(DISTINCT mw.movie_id) > 5
ORDER BY 
    total_movies DESC NULLS LAST
LIMIT 10
OFFSET 5;
