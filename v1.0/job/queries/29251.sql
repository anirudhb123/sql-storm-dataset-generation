WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
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
        RANK() OVER (ORDER BY company_count DESC, keyword_count DESC) AS rank
    FROM 
        RankedTitles
)
SELECT 
    tt.title,
    tt.production_year,
    tt.company_count,
    tt.keyword_count,
    p.name AS main_actor,
    r.role AS role
FROM 
    TopTitles tt
JOIN 
    complete_cast cc ON tt.title_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name p ON ci.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    tt.rank <= 10
ORDER BY 
    tt.company_count DESC, tt.keyword_count DESC, p.name;
