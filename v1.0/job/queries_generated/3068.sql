WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year IS NOT NULL
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
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        TopMovies m
    INNER JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    ARRAY_AGG(DISTINCT k.keyword) AS Keywords,
    STRING_AGG(DISTINCT c.company_name, ', ') AS Companies,
    COALESCE(MAX(CASE WHEN c.company_type = 'Producer' THEN c.company_name END), 'No Producer') AS Producer
FROM 
    TopMovies m
LEFT JOIN 
    MovieKeywords k ON m.title = k.title
LEFT JOIN 
    CompanyDetails c ON m.title = c.title
GROUP BY 
    m.title, m.production_year
ORDER BY 
    m.production_year DESC, m.title;
