
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopTitles AS (
    SELECT 
        rb.title_id,
        rb.title,
        rb.production_year,
        rb.kind_id,
        rb.company_count
    FROM 
        RankedTitles rb
    WHERE 
        rb.rank <= 3  
)
SELECT 
    tt.title,
    tt.production_year,
    kt.kind AS movie_kind,
    COUNT(DISTINCT ci.person_id) AS cast_member_count,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names
FROM 
    TopTitles tt
LEFT JOIN 
    aka_title at ON tt.title_id = at.movie_id
LEFT JOIN 
    cast_info ci ON tt.title_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON tt.title_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    kind_type kt ON tt.kind_id = kt.id
GROUP BY 
    tt.title, tt.production_year, kt.kind, tt.title_id, tt.kind_id, tt.company_count
ORDER BY 
    tt.production_year, tt.company_count DESC;
