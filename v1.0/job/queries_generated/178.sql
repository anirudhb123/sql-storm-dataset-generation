WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COALESCE(SUM(mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL), 'No Keywords') AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        a.production_year >= 2000 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        keywords, 
        cast_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
NullCheck AS (
    SELECT 
        tm.movie_title,
        CASE 
            WHEN tm.cast_count IS NULL THEN 'No Cast Info'
            ELSE CAST(tm.cast_count AS text)
        END AS cast_info
    FROM 
        TopMovies tm
)
SELECT 
    nt.name AS actor_name,
    nc.name AS character_name,
    t.movie_title,
    t.production_year,
    t.keywords,
    t.cast_info
FROM 
    NullCheck t
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = t.movie_title LIMIT 1)
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name nt ON ci.person_id = nt.person_id
LEFT JOIN 
    char_name nc ON ci.role_id = nc.id
WHERE 
    nt.name IS NOT NULL 
ORDER BY 
    t.production_year DESC, 
    t.cast_info DESC;
