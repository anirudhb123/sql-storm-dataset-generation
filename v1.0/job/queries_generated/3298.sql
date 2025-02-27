WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 3
),
MovieKeywords AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id
),
CompanyMovies AS (
    SELECT 
        m.title,
        c.name AS company_name,
        COALESCE(mt.kind, 'N/A') AS company_type,
        COUNT(mc.id) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type mt ON mc.company_type_id = mt.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        m.title, c.name, company_type
)
SELECT 
    tm.title,
    tm.production_year,
    mk.keywords,
    cm.company_name,
    cm.company_type,
    cm.num_movies
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.movie_id
LEFT JOIN 
    CompanyMovies cm ON tm.title = cm.title
ORDER BY 
    tm.production_year DESC, tm.title;
