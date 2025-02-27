WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        *,
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
        tm.aliases,
        tm.keywords,
        mt.kind AS movie_type,
        COUNT(mcc.company_id) AS company_count
    FROM 
        TopMovies AS tm
    LEFT JOIN 
        movie_companies AS mcc ON tm.movie_id = mcc.movie_id
    LEFT JOIN 
        kind_type AS mt ON tm.kind_id = mt.id
    WHERE 
        tm.rank <= 10
    GROUP BY 
        tm.movie_id, mt.kind
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.aliases,
    md.keywords,
    md.movie_type,
    md.company_count
FROM 
    MovieDetails AS md
ORDER BY 
    md.rank;
