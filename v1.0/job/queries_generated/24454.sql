WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(SUM(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
DirectorsInfo AS (
    SELECT 
        p.person_id,
        p.name,
        pi.info AS director_info
    FROM 
        aka_name p
    JOIN 
        person_info pi ON p.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
),
DetailedMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(dm.director_info, 'Unknown') AS director_info,
        rm.cast_count,
        CASE 
            WHEN rm.cast_count > 10 THEN 'Blockbuster'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Moderate Success'
            ELSE 'Indie Film' 
        END AS success_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        DirectorsInfo dm ON rm.movie_id = (SELECT movie_id FROM complete_cast WHERE subject_id = dm.person_id LIMIT 1)
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.cast_count,
    dmi.director_info,
    dmi.success_category
FROM 
    DetailedMovieInfo dmi
WHERE 
    dmi.production_year IN (SELECT DISTINCT production_year FROM DetailedMovieInfo WHERE cast_count > 0)
    AND dmi.success_category IN ('Blockbuster', 'Moderate Success')
ORDER BY 
    dmi.production_year DESC, dmi.cast_count DESC
LIMIT 10;

-- Additional part introducing a string expression and NULL logic
UNION ALL

SELECT 
    COALESCE(m.title || ' - A potential gem!', 'No title available') AS movie_title,
    m.production_year,
    COALESCE(ROUND(AVG(c.nr_order + 1), 2), 0) AS avg_order,
    COALESCE(d.info, 'Director Unknown') AS film_director,
    CASE 
        WHEN m.production_year IS NULL THEN 'Year Undisclosed'
        ELSE 'Year ' || m.production_year 
    END AS film_year_status
FROM 
    aka_title m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    DirectorsInfo d ON d.person_id = (SELECT person_id FROM complete_cast WHERE movie_id = m.id LIMIT 1)
WHERE 
    m.production_year IS NOT NULL OR m.id IS NULL
GROUP BY 
    m.title, m.production_year, d.info
HAVING 
    COUNT(c.id) < 3
ORDER BY 
    avg_order DESC
LIMIT 5;
