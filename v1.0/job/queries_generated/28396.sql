WITH RankedMovies AS (
    SELECT 
        a.id AS aka_title_id,
        a.title,
        a.production_year,
        a.kind_id,
        a.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.kind_id DESC) AS rank_by_year
    FROM 
        aka_title a
    WHERE 
        a.production_year >= 2000
),
TopMovies AS (
    SELECT 
        m.aka_title_id,
        m.title,
        m.production_year,
        m.kind_id
    FROM 
        RankedMovies m
    WHERE 
        m.rank_by_year <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.kind_id,
    cd.total_cast,
    cd.cast_names,
    mk.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.aka_title_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON tm.aka_title_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
