WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS alias_names
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    ct.kind AS category,
    tm.cast_count,
    tm.alias_names
FROM 
    TopMovies tm
JOIN 
    kind_type ct ON tm.kind_id = ct.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
