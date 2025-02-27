WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_with_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year > 1990
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_with_cast <= 10
),
MovieInfoWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tk.keyword,
        mi.info AS movie_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
    ORDER BY 
        tm.production_year DESC, tk.keyword
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    COALESCE(info.movie_info, 'No Info Available') AS movie_plot,
    COUNT(DISTINCT c.person_id) AS cast_count,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS actors_with_notes,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names
FROM 
    MovieInfoWithKeywords m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
GROUP BY 
    m.title, m.production_year, k.keyword, info.movie_info
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    m.production_year DESC, COUNT(DISTINCT c.person_id) DESC;
