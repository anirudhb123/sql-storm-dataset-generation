WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        CONCAT(a.name, ' as ', r.role) AS cast_member,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
),

KeywordCounts AS (
    SELECT 
        k.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM 
        keyword k
    JOIN 
        movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(mk.movie_id) > 5
),

CompanyDetails AS (
    SELECT 
        c.id AS company_id,
        c.name,
        ct.kind AS company_type,
        COUNT(mc.movie_id) AS movie_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        c.id, c.name, ct.kind
)

SELECT 
    rt.title,
    rt.production_year,
    rt.cast_member,
    kc.keyword,
    cd.name AS company_name,
    cd.company_type,
    cd.movie_count AS company_movie_count,
    rt.year_rank
FROM 
    RankedTitles rt
LEFT JOIN 
    KeywordCounts kc ON rt.title LIKE '%' || kc.keyword || '%'
LEFT JOIN 
    CompanyDetails cd ON rt.title_id IN (SELECT mc.movie_id FROM movie_companies mc WHERE mc.movie_id = rt.title_id)
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.year_rank, 
    cd.movie_count DESC;
