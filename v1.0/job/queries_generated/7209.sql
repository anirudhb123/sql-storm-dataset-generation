WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id, 
        tm.title,
        mci.name AS company_name,
        mk.keyword AS movie_keyword
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name mci ON mc.company_id = mci.id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
)

SELECT 
    md.title, 
    md.production_year, 
    STRING_AGG(DISTINCT md.company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
FROM 
    MovieDetails md
GROUP BY 
    md.title, md.production_year
ORDER BY 
    md.production_year DESC, md.title;
