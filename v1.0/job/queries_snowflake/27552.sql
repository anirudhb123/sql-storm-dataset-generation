
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5  
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.cast_count,
        LISTAGG(DISTINCT cn.name, ', ') AS companies,
        LISTAGG(DISTINCT n.name, ', ') AS character_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        name n ON cc.subject_id = n.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.cast_count
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.companies,
    md.character_names
FROM 
    MovieDetails md
ORDER BY 
    md.production_year, md.cast_count DESC;
