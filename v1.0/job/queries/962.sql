
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT * FROM RankedMovies WHERE year_rank <= 5
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
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ac.name, 'Unknown Actor') AS lead_actor,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = tm.title_id
LEFT JOIN 
    aka_name ac ON ci.person_id = ac.person_id AND ac.md5sum IS NOT NULL
GROUP BY 
    tm.title, tm.production_year, mk.keywords, ac.name
ORDER BY 
    tm.production_year DESC, tm.title;
