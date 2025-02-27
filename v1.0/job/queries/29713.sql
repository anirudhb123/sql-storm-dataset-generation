WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY LENGTH(a.title) DESC, a.title ASC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
MostCommonKeywords AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS keyword_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 10
),
TopCompanies AS (
    SELECT 
        c.name AS company_name,
        COUNT(mc.movie_id) AS total_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    GROUP BY 
        c.name
    ORDER BY 
        total_movies DESC
    LIMIT 5
)
SELECT 
    rt.movie_title,
    rt.production_year,
    rt.kind_id,
    k.keyword AS common_keyword,
    tc.company_name,
    tc.total_movies
FROM 
    RankedTitles rt
JOIN 
    MostCommonKeywords k ON rt.movie_title LIKE '%' || k.keyword || '%'
JOIN 
    TopCompanies tc ON rt.kind_id = (SELECT kind_id FROM kind_type WHERE kind = 'Film')
WHERE 
    rt.title_rank <= 10
ORDER BY 
    rt.production_year DESC, 
    k.keyword_count DESC, 
    rt.movie_title;
