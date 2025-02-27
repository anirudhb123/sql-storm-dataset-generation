WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        c.name AS company_name,
        ct.kind AS company_type,
        m.production_year,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    WHERE 
        c.country_code IS NOT NULL 
    GROUP BY 
        c.name, ct.kind, m.production_year
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        k.keyword,
        t.production_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredTitles AS (
    SELECT 
        m.title,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.title
)
SELECT 
    r.title,
    r.production_year,
    COALESCE(ci.movie_count, 0) AS company_movie_count,
    ft.cast_count,
    wk.keyword
FROM 
    RankedMovies r
LEFT JOIN 
    CompanyInfo ci ON r.production_year = ci.production_year
LEFT JOIN 
    FilteredTitles ft ON r.title = ft.title
LEFT JOIN 
    MoviesWithKeywords wk ON r.title = wk.title
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, r.title;
