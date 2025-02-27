WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
FilteredTitles AS (
    SELECT 
        rt.title_id, 
        rt.title, 
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 10
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title at ON at.id = mk.movie_id
    WHERE 
        at.kind_id = 1 -- assuming `1` corresponds to 'feature film'
),
TitleKeywordSummary AS (
    SELECT 
        ft.title,
        ft.production_year,
        string_agg(mk.keyword, ', ') AS keywords
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        MoviesWithKeywords mk ON ft.title_id = mk.movie_id
    GROUP BY 
        ft.title, ft.production_year
),
NameDetail AS (
    SELECT 
        a.name AS aka_name, 
        p.gender,
        c.name AS company_name
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        company_name c ON ci.movie_id = c.imdb_id
    JOIN 
        name p ON a.person_id = p.imdb_id
)
SELECT 
    ts.title,
    ts.production_year,
    ts.keywords,
    nd.aka_name,
    nd.gender,
    nd.company_name
FROM 
    TitleKeywordSummary ts
JOIN 
    NameDetail nd ON ts.production_year = (SELECT MAX(production_year) FROM title WHERE title = ts.title) 
ORDER BY 
    ts.production_year DESC, 
    ts.title;
