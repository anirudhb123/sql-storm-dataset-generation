WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        cc.cast_count
    FROM 
        title m
    JOIN 
        CastCounts cc ON m.id = cc.movie_id
    WHERE 
        m.production_year >= 1980
),
GenreKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
HostCompany AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    COALESCE(kw.keywords, 'No Keywords') AS keywords,
    COALESCE(hc.companies, 'No Companies') AS companies
FROM 
    MovieDetails md
LEFT JOIN 
    GenreKeywords kw ON md.movie_id = kw.movie_id
LEFT JOIN 
    HostCompany hc ON md.movie_id = hc.movie_id
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC, 
    md.title ASC
LIMIT 100;
