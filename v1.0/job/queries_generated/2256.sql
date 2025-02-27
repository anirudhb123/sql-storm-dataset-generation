WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
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
        actor_count_rank = 1
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
CompanyInformation AS (
    SELECT 
        a.title,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    mk.title,
    mk.keyword,
    ci.company_name,
    ci.company_type
FROM 
    MovieKeywords mk
FULL OUTER JOIN 
    CompanyInformation ci ON mk.title = ci.title
WHERE 
    mk.keyword IS NOT NULL OR ci.company_name IS NOT NULL
ORDER BY 
    mk.title, ci.company_name;
