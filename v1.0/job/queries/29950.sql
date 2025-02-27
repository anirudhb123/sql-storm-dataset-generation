WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        a.imdb_index AS aka_imdb_index,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
),
FilteredTitles AS (
    SELECT 
        aka_id,
        aka_name,
        movie_title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 3 
),
KeywordCounts AS (
    SELECT 
        t.id AS title_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
),
CompanyInformation AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    ft.aka_id,
    ft.aka_name,
    ft.movie_title,
    ft.production_year,
    kc.keyword_count,
    ci.companies
FROM 
    FilteredTitles ft
LEFT JOIN 
    KeywordCounts kc ON ft.aka_id = kc.title_id
LEFT JOIN 
    CompanyInformation ci ON ft.aka_id = ci.movie_id
ORDER BY 
    ft.production_year DESC, ft.aka_name;