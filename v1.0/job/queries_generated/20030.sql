WITH RankedTitles AS (
    SELECT 
        a.person_id,
        b.movie_id,
        b.title,
        b.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY b.production_year DESC) AS rn,
        COALESCE(b.kind_id, -1) AS type_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title b ON ci.movie_id = b.movie_id
    WHERE 
        b.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        rt.person_id,
        rt.title,
        rt.production_year,
        rt.type_id
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 5
        AND rt.type_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Drama%')
),
TitleCast AS (
    SELECT 
        ft.person_id,
        ft.title,
        ft.production_year,
        COUNT(DISTINCT ci.id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        cast_info ci ON ft.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id LIMIT 1) 
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ft.person_id, ft.title, ft.production_year
),
FinalPerformance AS (
    SELECT 
        tc.person_id,
        tc.title,
        tc.production_year,
        CASE 
            WHEN tc.actor_count IS NULL THEN 'No Actors'
            WHEN tc.actor_count > 0 THEN 'Actors Present'
            ELSE 'Unknown'
        END AS actor_status,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT movie_id FROM aka_title WHERE title = tc.title)) AS info_count,
        CASE 
            WHEN info_count = 0 THEN 'No Additional Info'
            ELSE 'Additional Info Available'
        END AS info_status
    FROM 
        TitleCast tc
)
SELECT 
    fp.person_id,
    fp.title,
    fp.production_year,
    fp.actor_status,
    fp.info_status,
    CONCAT(fp.title, ' - ' , CAST(fp.production_year AS VARCHAR)) AS title_with_year,
    LEAD(fp.production_year) OVER (PARTITION BY fp.person_id ORDER BY fp.production_year DESC) AS next_year,
    LAG(fp.production_year) OVER (PARTITION BY fp.person_id ORDER BY fp.production_year DESC) AS prev_year
FROM 
    FinalPerformance fp
ORDER BY 
    fp.production_year DESC, fp.person_id;
