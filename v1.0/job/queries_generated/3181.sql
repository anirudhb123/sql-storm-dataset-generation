WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT m.company_id) AS company_count,
        DENSE_RANK() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS ranking
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    GROUP BY 
        a.title, a.production_year, a.kind_id
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        kind_id 
    FROM 
        RankedMovies 
    WHERE 
        ranking <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
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
    kt.kind AS kind,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT c.person_id) AS actor_count,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present
FROM 
    TopMovies tm
JOIN 
    kind_type kt ON tm.kind_id = kt.id
LEFT JOIN 
    complete_cast cc ON tm.id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.id
LEFT JOIN 
    MovieKeywords mk ON tm.id = mk.movie_id
GROUP BY 
    tm.title, tm.production_year, kt.kind, mk.keywords
ORDER BY 
    tm.production_year DESC, actor_count DESC;
