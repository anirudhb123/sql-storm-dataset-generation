WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
PopularTitles AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    pt.title,
    pt.production_year,
    cd.company_name,
    cd.company_type,
    mk.keywords
FROM 
    PopularTitles pt
LEFT JOIN 
    CompanyDetails cd ON pt.title = (SELECT title FROM aka_title WHERE id = cd.movie_id LIMIT 1)
LEFT JOIN 
    MovieKeywords mk ON pt.title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
WHERE 
    cd.company_type IS NOT NULL OR mk.keywords IS NOT NULL
ORDER BY 
    pt.production_year DESC, 
    pt.title;
