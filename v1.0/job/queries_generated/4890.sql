WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS actor_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
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
        rank = 1
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = m.title)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT 
        m.title,
        COUNT(mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = (SELECT id FROM aka_title WHERE title = m.title)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.title
)
SELECT 
    mk.title,
    mk.keyword,
    cd.company_count,
    cd.companies
FROM 
    MovieKeywords mk
JOIN 
    CompanyDetails cd ON mk.title = cd.title
WHERE 
    cd.company_count IS NOT NULL
ORDER BY 
    cd.company_count DESC, mk.title ASC;
