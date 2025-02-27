WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count,
        rm.cast_count,
        kt.kind AS kind
    FROM 
        RankedMovies rm
    JOIN 
        kind_type kt ON rm.kind_id = kt.id
    WHERE 
        rm.rank <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    tm.kind,
    tm.keyword_count,
    tm.cast_count,
    n.name AS director_name
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
ORDER BY 
    tm.production_year DESC, tm.title;
