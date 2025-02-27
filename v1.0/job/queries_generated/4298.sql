WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(g.kind, 'Unknown') AS genre,
        COALESCE(c.nationality, 'Unknown') AS nationality,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        RankedMovies m
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN movie_companies mc ON mc.movie_id = m.movie_id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN kind_type g ON g.id = mc.company_type_id
    GROUP BY 
        m.movie_id, m.title, m.production_year, g.kind, c.nationality
),
TopTenMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.genre,
        md.nationality,
        md.keyword_count
    FROM 
        MovieDetails md
    WHERE 
        md.production_year >= 2000
    ORDER BY 
        md.keyword_count DESC
    LIMIT 10
)
SELECT 
    t.movie_id,
    t.title,
    t.production_year,
    t.genre,
    t.nationality,
    t.keyword_count,
    COALESCE((SELECT AVG(ri.rating) 
              FROM reviews ri 
              WHERE ri.movie_id = t.movie_id), 0) AS average_rating
FROM 
    TopTenMovies t
LEFT JOIN movie_info mi ON mi.movie_id = t.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
LEFT JOIN (SELECT DISTINCT movie_id, COUNT(*) AS review_count FROM reviews GROUP BY movie_id) r ON r.movie_id = t.movie_id
ORDER BY 
    average_rating DESC NULLS LAST;
