WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(ck.keyword) AS keyword_count
    FROM 
        aka_title at
    JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    JOIN 
        keyword ck ON mk.keyword_id = ck.id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopKeywords AS (
    SELECT 
        title_id,
        keyword_count,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedTitles
    WHERE 
        production_year BETWEEN 2000 AND 2020
),
PeopleCast AS (
    SELECT 
        ai.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id 
    WHERE 
        ai.name LIKE '%Smith%'
    GROUP BY 
        ai.person_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tt.title AS Movie_Title,
    tt.production_year AS Year,
    tk.keyword_count AS Keyword_Count,
    pc.movie_count AS Actor_Movie_Count,
    cm.company_name AS Production_Company,
    cm.company_type AS Company_Type
FROM 
    TopKeywords tk
JOIN 
    RankedTitles tt ON tk.title_id = tt.title_id
JOIN 
    PeopleCast pc ON pc.movie_count > 5 
JOIN 
    CompanyMovies cm ON cm.movie_id = tt.title_id
WHERE 
    tk.rank <= 10 
ORDER BY 
    tk.keyword_count DESC, tt.production_year ASC;