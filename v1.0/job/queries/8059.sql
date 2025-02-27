
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY a.name) AS title_rank
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        aka_name a ON at.id = a.id
),
MovieDetails AS (
    SELECT 
        mc.movie_id,
        c.kind AS company_type,
        STRING_AGG(DISTINCT m.name) AS companies,
        STRING_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_companies mc
    JOIN 
        company_name m ON mc.company_id = m.id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mc.movie_id,
        c.kind
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    md.company_type,
    md.companies,
    md.keywords
FROM 
    RankedTitles rt
JOIN 
    complete_cast cc ON rt.title_id = cc.movie_id
JOIN 
    MovieDetails md ON cc.movie_id = md.movie_id
WHERE 
    rt.title_rank <= 5 AND 
    rt.production_year > 2000
ORDER BY 
    rt.production_year DESC, 
    rt.title;
