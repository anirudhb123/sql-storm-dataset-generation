WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        company_count,
        keyword_count,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC, company_count DESC) AS rank
    FROM 
        RankedTitles
)
SELECT 
    tt.title_id,
    tt.title,
    tt.production_year,
    tt.company_count,
    tt.keyword_count,
    a.name AS actor_name,
    ct.kind AS company_type,
    rt.role
FROM 
    TopTitles tt
JOIN 
    complete_cast cc ON tt.title_id = cc.movie_id
JOIN 
    aka_name a ON cc.subject_id = a.person_id
JOIN 
    movie_companies mc ON tt.title_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    cast_info ci ON cc.id = ci.id
JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    tt.rank <= 10
ORDER BY 
    tt.production_year DESC, 
    tt.keyword_count DESC, 
    tt.company_count DESC;
