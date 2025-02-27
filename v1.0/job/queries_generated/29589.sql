WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        aka_title AS ak ON t.id = ak.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        title,
        production_year,
        company_count,
        aka_names,
        RANK() OVER (ORDER BY company_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    tm.aka_names,
    GROUP_CONCAT(DISTINCT ci.note ORDER BY ci.note) AS cast_notes,
    GROUP_CONCAT(DISTINCT ki.keyword ORDER BY ki.keyword) AS movie_keywords
FROM 
    TopMovies AS tm
LEFT JOIN 
    complete_cast AS cc ON tm.title = (SELECT title FROM title WHERE id = cc.movie_id)
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = cc.movie_id
LEFT JOIN 
    keyword AS ki ON mk.keyword_id = ki.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, tm.company_count, tm.aka_names
ORDER BY 
    tm.company_count DESC;

This query benchmarks string processing by aggregating data across multiple tables related to movies, their companies, alternative names, cast information, and keywords. It first ranks movies by the number of associated companies, gathers alternative names for those movies, and finally collects notes from the cast and keywords to get a comprehensive view of the top 10 movies with the most companies.
