WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id 
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        num_cast,
        cast_names,
        keywords,
        RANK() OVER (ORDER BY num_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    kt.kind AS movie_kind,
    tm.num_cast,
    tm.cast_names,
    tm.keywords
FROM 
    TopMovies tm
JOIN 
    kind_type kt ON tm.kind_id = kt.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
