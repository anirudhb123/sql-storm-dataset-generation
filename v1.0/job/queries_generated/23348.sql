WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(c1.note, 'No Role') AS main_role,
        CAST(COALESCE(c1.nr_order, 999) AS integer) AS ranking_order,
        COUNT(c2.person_id) FILTER (WHERE c2.person_id IS NOT NULL) AS co_stars_count
    FROM 
        RankedMovies r
    LEFT JOIN
        cast_info c1 ON r.movie_id = c1.movie_id AND c1.nr_order = (SELECT MIN(nr_order) FROM cast_info WHERE movie_id = r.movie_id)
    LEFT JOIN
        cast_info c2 ON r.movie_id = c2.movie_id AND c2.person_id <> c1.person_id
    GROUP BY 
        r.movie_id, r.title, r.production_year, c1.note, c1.nr_order
    HAVING 
        COUNT(DISTINCT c2.person_id) > 0
),
InterestingRoles AS (
    SELECT 
        DISTINCT c.person_id,
        a.name AS actor_name,
        r.role AS role_type
    FROM 
        cast_info c
    JOIN 
        name a ON c.person_id = a.imdb_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.gender = 'F' -- focusing on female actors
        AND r.role ILIKE '%lead%'
),
FinalResults AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.main_role,
        tm.co_stars_count,
        ir.actor_name,
        ir.role_type,
        ROW_NUMBER() OVER (PARTITION BY tm.movie_id ORDER BY ir.actor_name) AS actress_rank
    FROM 
        TopMovies tm
    LEFT JOIN 
        InterestingRoles ir ON tm.movie_id IN (SELECT DISTINCT movie_id FROM cast_info WHERE person_id = ir.person_id)
)
SELECT 
    fr.title,
    fr.production_year,
    fr.main_role,
    fr.co_stars_count,
    fr.actor_name,
    fr.role_type,
    CASE 
        WHEN fr.co_stars_count >= 5 THEN 'Ensemble Cast'
        WHEN fr.co_stars_count BETWEEN 3 AND 4 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    MAX(fr.actress_rank) OVER (PARTITION BY fr.movie_id) AS max_actress_rank
FROM 
    FinalResults fr
WHERE 
    fr.co_stars_count > 2
ORDER BY
    fr.production_year DESC, fr.co_stars_count DESC, fr.title;

