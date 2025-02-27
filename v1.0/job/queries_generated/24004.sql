WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN char.name IS NOT NULL THEN 1 ELSE 0 END) AS has_character_name
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast mc ON mt.id = mc.movie_id
    LEFT JOIN 
        cast_info c ON mc.subject_id = c.id
    LEFT JOIN 
        char_name char ON c.person_id = char.imdb_id
    WHERE 
        mt.production_year >= 2000 
        AND mt.production_year < 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

TopGenres AS (
    SELECT 
        g.kind_id,
        COUNT(DISTINCT m.id) AS genre_count
    FROM 
        kind_type g
    JOIN 
        aka_title m ON g.id = m.kind_id
    WHERE 
        g.kind IS NOT NULL
    GROUP BY 
        g.kind_id
    HAVING 
        COUNT(DISTINCT m.id) > 5
),

PopularMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        tg.genre_count
    FROM 
        RankedMovies rm
    JOIN 
        TopGenres tg ON rm.total_cast >= 5
    WHERE 
        rm.has_character_name > 0.5
)

SELECT 
    pm.title,
    pm.production_year,
    COALESCE(pm.genre_count, 0) AS genre_count,
    CASE 
        WHEN pm.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(pm.production_year AS TEXT)
    END AS year_description,
    STRING_AGG(DISTINCT ci.note, '; ') AS cast_notes
FROM 
    PopularMovies pm
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT id FROM aka_title WHERE title = pm.title)
GROUP BY 
    pm.title, pm.production_year, pm.genre_count 
ORDER BY 
    pm.production_year DESC,
    pm.title;

