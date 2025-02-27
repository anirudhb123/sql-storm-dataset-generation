WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), MovieDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(mi.info IS NOT NULL)::int AS has_info,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        cast_info ci
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        movie_info mi ON cc.movie_id = mi.movie_id
    JOIN 
        movie_keyword mk ON cc.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        c.movie_id
), CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    md.cast_count,
    md.has_info,
    cc.company_count,
    md.keywords
FROM 
    RankedTitles rt
JOIN 
    MovieDetails md ON rt.title = md.title
JOIN 
    CompanyCounts cc ON md.movie_id = cc.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    md.cast_count DESC;
