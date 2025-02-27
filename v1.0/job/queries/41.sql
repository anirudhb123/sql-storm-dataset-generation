WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywordCounts AS (
    SELECT
        m.movie_id,
        COUNT(mk.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN 
        TopMovies m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COUNT(DISTINCT ca.person_id) AS actor_count,
    STRING_AGG(aka.name, ', ') AS actor_names,
    MAX(CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS birth_info,
    MAX(CASE WHEN pi.info_type_id = 2 THEN pi.info END) AS death_info
FROM 
    TopMovies m
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    MovieKeywordCounts kc ON m.movie_id = kc.movie_id
LEFT JOIN 
    cast_info ca ON m.movie_id = ca.movie_id
LEFT JOIN 
    aka_name aka ON ca.person_id = aka.person_id 
LEFT JOIN 
    person_info pi ON ca.person_id = pi.person_id
GROUP BY 
    m.movie_id, m.title, m.production_year, kc.keyword_count
ORDER BY 
    m.production_year DESC, keyword_count DESC;
