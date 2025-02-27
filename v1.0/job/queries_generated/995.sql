WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyMovieInfo AS (
    SELECT 
        m.title,
        co.name AS company_name,
        ct.kind AS company_type,
        t.info_type_id,
        t.info
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info t ON t.movie_id = m.id
)
SELECT 
    m.title,
    m.production_year,
    km.keyword AS movie_keyword,
    c.company_name,
    c.company_type,
    COALESCE(i.info, 'No Info Available') AS additional_info
FROM 
    TopMovies m
LEFT JOIN 
    MovieKeywords km ON m.title = km.title
LEFT JOIN 
    CompanyMovieInfo c ON m.title = c.title
LEFT JOIN 
    movie_info_idx i ON m.title = i.movie_id AND i.info_type_id = 1  -- Assuming 1 is a specific info_type_id
WHERE 
    (c.company_name IS NOT NULL OR km.keyword IS NOT NULL)
ORDER BY 
    m.production_year DESC, m.title;
