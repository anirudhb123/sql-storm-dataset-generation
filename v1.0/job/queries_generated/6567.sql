WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.keyword,
    tm.total_cast,
    COUNT(DISTINCT pc.info) AS unique_personal_info
FROM 
    TopMovies tm
LEFT JOIN 
    person_info pi ON pi.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = tm.movie_id)
LEFT JOIN 
    info_type it ON pi.info_type_id = it.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.keyword, tm.total_cast
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
