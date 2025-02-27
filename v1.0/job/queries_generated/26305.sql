WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_cast DESC) AS cast_rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.aka_names,
    tm.keywords,
    ci.role_id,
    rt.role
FROM 
    TopMovies AS tm
JOIN 
    complete_cast AS cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info AS ci ON cc.subject_id = ci.id
JOIN 
    role_type AS rt ON ci.role_id = rt.id
WHERE 
    tm.cast_rank <= 10
ORDER BY 
    tm.total_cast DESC, 
    tm.production_year DESC;
