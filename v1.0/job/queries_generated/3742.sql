WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        COALESCE(b.keywords, 'No Keywords') AS keywords
    FROM 
        aka_title a
    LEFT JOIN (
        SELECT 
            mt.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        JOIN 
            movie_info mi ON mk.movie_id = mi.movie_id
        GROUP BY 
            mt.movie_id
    ) b ON a.movie_id = b.movie_id
),
FilteredTitles AS (
    SELECT 
        rt.title, 
        rt.production_year, 
        rt.title_rank,
        COALESCE(SUBSTRING(rt.keywords FROM 1 FOR 20), 'No Keywords') AS short_keywords
    FROM 
        RankedTitles rt
    WHERE 
        rt.production_year > 2000 
        AND rt.title_rank <= 5
),
MovieDetails AS (
    SELECT 
        f.title,
        f.production_year,
        COALESCE(mc.company_count, 0) AS company_count
    FROM 
        FilteredTitles f
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            COUNT(*) AS company_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) mc ON f.title = mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    CASE 
        WHEN md.company_count > 0 THEN 'Produced by Company'
        ELSE 'Independent Film'
    END AS film_type
FROM 
    MovieDetails md
WHERE 
    md.company_count IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title;
