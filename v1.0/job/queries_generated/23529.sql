WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
), 
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MoviesWithInfo AS (
    SELECT 
        tm.title,
        tm.production_year,
        mi.info AS movie_info,
        COALESCE(NULLIF(mi.note, ''), 'No notes available') AS note_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.production_year = mi.movie_id
),
MoviesWithCharacters AS (
    SELECT 
        mw.title,
        mw.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS character_names,
        CASE 
            WHEN COUNT(DISTINCT cn.id) IS NULL THEN 'None'
            ELSE 'Has characters'
        END AS character_presence
    FROM 
        MoviesWithInfo mw
    LEFT JOIN 
        complete_cast cc ON mw.title = cc.movie_id
    LEFT JOIN 
        char_name cn ON cc.subject_id = cn.id
    GROUP BY 
        mw.title, mw.production_year
)
SELECT 
    mw.title,
    mw.production_year,
    mw.movie_info,
    mw.note_info,
    mc.character_names,
    mc.character_presence,
    (SELECT AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) FROM cast_info ci WHERE ci.movie_id IN (SELECT movie_id FROM aka_title WHERE title = mw.title)) AS average_cast_role_presence
FROM 
    MoviesWithInfo mw
JOIN 
    MoviesWithCharacters mc ON mw.title = mc.title
WHERE 
    mw.production_year > 2000
ORDER BY 
    mw.production_year DESC, 
    mc.character_presence DESC;
