
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        aka_id, 
        aka_name, 
        title_id, 
        title, 
        production_year 
    FROM 
        RankedTitles 
    WHERE 
        rn <= 3
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tt.aka_name,
    LISTAGG(tt.title || ' (' || tt.production_year || ')', ', ') WITHIN GROUP (ORDER BY tt.production_year) AS title_list,
    COUNT(DISTINCT mc.company_name) AS company_count,
    MAX(CASE WHEN mc.company_type = 'Distributor' THEN mc.company_name ELSE NULL END) AS distributor_name,
    COUNT(DISTINCT t.keyword) AS keyword_count
FROM 
    TopTitles tt
LEFT JOIN 
    movie_keyword mk ON tt.title_id = mk.movie_id
LEFT JOIN 
    keyword t ON mk.keyword_id = t.id
LEFT JOIN 
    MovieCompanies mc ON tt.title_id = mc.movie_id
GROUP BY 
    tt.aka_name
HAVING 
    COUNT(DISTINCT tt.title_id) >= 2
ORDER BY 
    company_count DESC, 
    tt.aka_name;
