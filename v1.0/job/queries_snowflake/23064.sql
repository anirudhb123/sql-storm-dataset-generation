
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
PersonMovieInfo AS (
    SELECT 
        ci.person_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        aka_name n ON n.person_id = ci.person_id
    WHERE 
        ci.role_id IS NOT NULL
    GROUP BY 
        ci.person_id, t.title, t.production_year
), 
YearStats AS (
    SELECT 
        production_year,
        AVG(movie_count) AS avg_movies,
        MAX(movie_count) AS max_movies
    FROM 
        PersonMovieInfo
    GROUP BY 
        production_year
), 
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS movie_keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title
)

SELECT 
    r.title_id,
    r.title,
    r.production_year,
    p.actor_names,
    s.avg_movies,
    s.max_movies,
    CASE 
        WHEN s.avg_movies IS NULL THEN 'No Movies'
        ELSE CAST(s.avg_movies AS TEXT)
    END AS avg_movies_display,
    COALESCE(mk.movie_keywords, 'No Keywords') AS keywords
FROM 
    RankedTitles r
LEFT JOIN 
    PersonMovieInfo p ON r.title = p.title AND r.production_year = p.production_year
LEFT JOIN 
    YearStats s ON r.production_year = s.production_year
LEFT JOIN 
    MoviesWithKeywords mk ON r.title_id = mk.movie_id
WHERE 
    r.year_rank <= 10
ORDER BY 
    r.production_year DESC, 
    r.title ASC
LIMIT 100;
