WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(k.id) AS keyword_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        RANK() OVER (ORDER BY COUNT(k.id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),

TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keywords,
        rm.rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),

MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        REPLACE(tm.title, ' ', '_') AS title_slug,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT cc.company_id) AS company_count
    FROM 
        TopMovies tm
    JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        tm.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.title_slug,
    md.actors,
    md.company_count
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title;
