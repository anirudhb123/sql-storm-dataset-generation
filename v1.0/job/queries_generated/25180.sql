WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
), 
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.title,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT mp.company_name, ', ') AS production_companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name mp ON mc.company_id = mp.id
    GROUP BY 
        tm.title
)

SELECT 
    md.title,
    md.total_cast,
    md.cast_names, 
    md.production_companies 
FROM 
    MovieDetails md
ORDER BY 
    md.total_cast DESC, 
    md.title ASC;
