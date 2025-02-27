WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        array_agg(DISTINCT ak.name) AS aka_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        cast_count,
        aka_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        tm.aka_names,
        COALESCE(mn.notes, 'No special notes') AS movie_notes,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mn ON tm.movie_id = mn.movie_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    WHERE 
        tm.rank <= 10
    GROUP BY 
        tm.movie_id, mn.notes
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.aka_names,
    md.movie_notes,
    md.keyword_count
FROM 
    MovieDetails md
ORDER BY 
    md.cast_count DESC, md.title ASC;
