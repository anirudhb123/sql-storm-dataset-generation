
WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        a.title, a.production_year, a.kind_id, a.id
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        kind_id,
        aka_names,
        keywords
    FROM 
        RankedTitles
    WHERE 
        year_rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    k.kind AS movie_kind,
    tm.aka_names,
    tm.keywords
FROM 
    TopMovies tm
JOIN 
    kind_type k ON tm.kind_id = k.id
ORDER BY 
    tm.production_year DESC, tm.movie_title;
