WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year, cast_count 
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.title,
        COALESCE(CAST(ki.keyword AS text), 'No Keywords') AS keyword,
        COALESCE(cn.name, 'Unknown Company') AS company_name,
        tm.cast_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
)
SELECT 
    md.title,
    md.keyword,
    md.company_name,
    md.cast_count,
    CASE
        WHEN md.cast_count > 5 THEN 'Popular'
        WHEN md.cast_count BETWEEN 3 AND 5 THEN 'Average'
        ELSE 'Minor'
    END AS popularity_level
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 50;
