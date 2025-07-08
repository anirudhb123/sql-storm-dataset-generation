WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) as rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 5
),
CompanyDetails AS (
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
    rt.aka_id,
    rt.title,
    rt.production_year,
    pk.keyword,
    cd.company_name,
    cd.company_type
FROM 
    RankedTitles rt
LEFT JOIN 
    PopularKeywords pk ON rt.aka_id = pk.movie_id
LEFT JOIN 
    CompanyDetails cd ON rt.production_year = cd.movie_id
WHERE 
    rt.rank = 1
    AND (cd.company_name IS NOT NULL OR pk.keyword IS NOT NULL)
ORDER BY 
    rt.production_year DESC, rt.title;
