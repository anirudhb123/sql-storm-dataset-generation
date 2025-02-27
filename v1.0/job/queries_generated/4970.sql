WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), HighestRatedMovies AS (
    SELECT 
        m.movie_id, 
        m.title,
        COALESCE(mi.info, 'No Rating') AS rating
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    WHERE 
        m.rn = 1
)
SELECT 
    hr.movie_id, 
    hr.title, 
    hr.rating, 
    mk.keywords
FROM 
    HighestRatedMovies hr
LEFT JOIN 
    MovieKeywords mk ON hr.movie_id = mk.movie_id
WHERE 
    hr.rating IS NOT NULL
ORDER BY 
    hr.production_year DESC, 
    hr.title;
