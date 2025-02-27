WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY at.production_year) AS titles_count
    FROM 
        aka_title AS at
    WHERE 
        at.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mt.id) AS company_count,
        COALESCE(AVG(mi.info::numeric), 0) AS average_movie_length
    FROM 
        title
    LEFT JOIN 
        complete_cast AS cc ON title.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies AS mc ON title.id = mc.movie_id
    LEFT JOIN 
        movie_info AS mi ON title.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'length')
    GROUP BY 
        title.id
),
TitleStats AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        md.company_count,
        md.average_movie_length,
        rt.title_rank,
        rt.titles_count
    FROM 
        MovieDetails AS md
    JOIN 
        RankedTitles AS rt ON md.production_year = rt.production_year
)
SELECT 
    ts.title,
    ts.production_year,
    CASE 
        WHEN ts.average_movie_length IS NULL THEN 'Unknown Length'
        ELSE CONCAT(ts.average_movie_length, ' minutes')
    END AS average_length,
    ts.cast_count,
    ts.company_count,
    CASE 
        WHEN ts.cast_count > 10 THEN 'Large Cast'
        WHEN ts.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    ts.title_rank,
    ts.titles_count
FROM 
    TitleStats AS ts
WHERE 
    ts.production_year >= 2000
    AND ts.average_movie_length IS NOT NULL 
    AND (ts.company_count > 0 OR ts.cast_count > 5) 
ORDER BY 
    ts.production_year DESC,
    ts.title;
