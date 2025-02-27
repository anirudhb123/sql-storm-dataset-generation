WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.movie_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (
            PARTITION BY t.production_year
            ORDER BY COUNT(mk.movie_id) DESC
        ) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_count,
        rt.keywords
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank <= 5
)

SELECT 
    a.name AS actor_name,
    tt.title AS movie_title,
    tt.production_year,
    cc.kind AS role_type,
    mp.company_name AS production_company,
    COUNT(ci.id) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title tt ON ci.movie_id = tt.id
JOIN 
    comp_cast_type cc ON ci.person_role_id = cc.id
JOIN 
    movie_companies mc ON tt.id = mc.movie_id
JOIN 
    company_name mp ON mc.company_id = mp.id
JOIN 
    TopTitles tt ON tt.title_id = tt.id
WHERE 
    mp.country_code = 'USA'
GROUP BY 
    a.name, tt.title, tt.production_year, cc.kind, mp.company_name
ORDER BY 
    movie_title, actor_name;
