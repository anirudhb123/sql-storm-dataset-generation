WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    mk.keywords,
    COALESCE(ak.name, 'Unknown') AS actor_name,
    COALESCE(ca.kind, 'N/A') AS cast_type,
    SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END) AS num_personal_infos,
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No Info' END) AS latest_note
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.production_year = mi.movie_id
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = mi.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    comp_cast_type ca ON ci.person_role_id = ca.id
LEFT JOIN 
    person_info pi ON pi.person_id = ak.person_id
WHERE 
    tm.production_year BETWEEN 2000 AND 2020
GROUP BY 
    tm.title, tm.production_year, mk.keywords, ak.name, ca.kind
HAVING 
    COUNT(DISTINCT ci.id) > 2
ORDER BY 
    tm.production_year DESC, COUNT(ci.id) DESC;
