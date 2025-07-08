
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS ranking
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.kind_id
    FROM 
        RankedMovies rm
    WHERE 
        rm.ranking <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.movie_title,
        tm.production_year,
        kt.kind AS kind_name,
        COUNT(ci.id) AS cast_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        kind_type kt ON tm.kind_id = kt.id
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    GROUP BY 
        tm.movie_id, tm.movie_title, tm.production_year, kt.kind
)
SELECT 
    md.movie_title,
    md.production_year,
    md.kind_name,
    md.cast_count,
    md.company_names AS companies
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.movie_title;
