
WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
), 
TopMovies AS (
    SELECT 
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 5
), 
CastMovieInfo AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        cn.name AS character_name,
        p.info AS person_info
    FROM 
        cast_info c
    LEFT JOIN 
        char_name cn ON cn.id = c.person_role_id
    LEFT JOIN 
        person_info p ON p.person_id = c.person_id
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(DISTINCT cmi.cast_id) AS cast_count,
    LISTAGG(DISTINCT cmi.character_name, ', ') WITHIN GROUP (ORDER BY cmi.character_name) AS character_names,
    COALESCE(MAX(p.info), 'No Info') AS director_info
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON cc.movie_id = tm.production_year
LEFT JOIN 
    CastMovieInfo cmi ON cmi.movie_id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = tm.production_year
LEFT JOIN 
    company_name co ON co.id = mc.company_id AND co.country_code IS NULL
LEFT JOIN 
    person_info p ON p.person_id = mc.company_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'director')
GROUP BY 
    tm.title, tm.production_year
HAVING 
    COUNT(DISTINCT cmi.cast_id) > 0
ORDER BY 
    tm.production_year DESC, tm.title ASC;
