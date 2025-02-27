WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_rating,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        t.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
)
SELECT 
    tr.movie_title,
    tr.production_year,
    mk.keywords,
    COALESCE(m.info, 'No Info Available') AS additional_info
FROM 
    TopRatedMovies tr
LEFT JOIN 
    MovieKeywords mk ON tr.movie_title = mk.title
LEFT JOIN 
    movie_info m ON (SELECT movie_id FROM aka_title WHERE title = tr.movie_title) = m.movie_id
WHERE 
    (m.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget') OR m.info IS NULL)
ORDER BY 
    tr.production_year DESC, tr.movie_title;
