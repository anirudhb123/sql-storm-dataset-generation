WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        k.keyword
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.actor_count > 0
),
HighRankedMovies AS (
    SELECT 
        r.title,
        r.production_year
    FROM 
        RankedMovies r
    WHERE 
        r.rank <= 5
)
SELECT 
    h.title,
    h.production_year,
    COALESCE(w.keyword, 'No Keywords') AS keyword,
    CASE 
        WHEN h.production_year >= 2000 THEN 'Modern'
        WHEN h.production_year >= 1980 THEN 'Classic'
        ELSE 'Vintage'
    END AS era,
    (SELECT COUNT(*) FROM movie_link ml WHERE ml.movie_id = (SELECT id FROM title WHERE title = h.title LIMIT 1)) AS related_links
FROM 
    HighRankedMovies h
LEFT JOIN 
    MoviesWithKeywords w ON h.title = w.title AND h.production_year = w.production_year
ORDER BY 
    h.production_year DESC, h.title;
