WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliased_names,
        STRING_AGG(DISTINCT kn.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kn ON mk.keyword_id = kn.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        aliased_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE(tm.aliased_names, 'No Aliases') AS aliased_names,
    COALESCE(tm.keywords, 'No Keywords') AS keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
