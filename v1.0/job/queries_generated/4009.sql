WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS num_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS cast_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        cast_rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    JOIN 
        movie_keyword mk ON mk.movie_id IN (SELECT id FROM aka_title WHERE title = m.title)
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
EnhancedMovies AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(STRING_AGG(DISTINCT mk.keyword, ', '), 'No Keywords') AS keywords
    FROM 
        TopMovies m
    LEFT JOIN 
        MovieKeywords mk ON mk.title = m.title
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    em.title,
    em.production_year,
    em.keywords,
    COALESCE(n.name, 'Unknown') AS director,
    COALESCE(AVG(r.rating), 0) AS average_rating
FROM 
    EnhancedMovies em
LEFT JOIN 
    movie_info mi ON em.title = mi.info AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
LEFT JOIN 
    person_info pi ON pi.person_id IN (SELECT person_id FROM cast_info WHERE movie_id IN (SELECT id FROM aka_title WHERE title = em.title) LIMIT 1)
LEFT JOIN 
    name n ON pi.info = n.name
LEFT JOIN 
    (SELECT 
        movie_id, 
        AVG(CASE WHEN info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN CAST(info AS DECIMAL) END) AS rating
    FROM 
        movie_info GROUP BY movie_id) r ON em.title = (SELECT title FROM aka_title WHERE id = r.movie_id)
WHERE 
    em.production_year > 2000
ORDER BY 
    em.production_year DESC, 
    em.title;
