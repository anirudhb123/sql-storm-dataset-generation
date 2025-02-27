WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
    HAVING 
        COUNT(ci.person_id) > 5
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        RANK() OVER (ORDER BY cast_count DESC) as rank_position
    FROM 
        RankedMovies
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    GROUP_CONCAT(DISTINCT pc.info ORDER BY pc.info_type_id) AS personnel_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
LEFT JOIN 
    info_type it ON pi.info_type_id = it.id
LEFT JOIN 
    (SELECT person_id, 
            STRING_AGG(info, ', ') AS info
     FROM 
            person_info 
     GROUP BY person_id
    ) pc ON pi.person_id = pc.person_id
WHERE 
    tm.rank_position <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.aka_names
ORDER BY 
    tm.cast_count DESC;
