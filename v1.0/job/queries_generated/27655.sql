WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
TopTitles AS (
    SELECT 
        title, 
        production_year, 
        company_count, 
        keyword_count
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
)
SELECT 
    tt.title,
    tt.production_year,
    tt.company_count,
    tt.keyword_count,
    ak.name AS actor_name,
    ct.kind AS company_type,
    rt.role AS role_type
FROM 
    TopTitles tt
LEFT JOIN 
    cast_info ci ON tt.title = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON tt.title = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
ORDER BY 
    tt.production_year DESC, 
    tt.company_count DESC;
