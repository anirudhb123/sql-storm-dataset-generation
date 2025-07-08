
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id, 
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        tm.title, tm.production_year, mk.keywords
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    CASE 
        WHEN md.production_year > 2000 THEN 'Modern Era'
        WHEN md.production_year BETWEEN 1980 AND 2000 THEN 'Classic Era'
        ELSE 'Old School'
    END AS era,
    COUNT(CASE WHEN ak.name IS NOT NULL THEN 1 END) AS featured_actors
FROM 
    MovieDetails md
LEFT JOIN 
    aka_name ak ON ak.name IS NOT NULL
GROUP BY 
    md.title, md.production_year, md.keywords
ORDER BY 
    md.production_year DESC, featured_actors DESC;
