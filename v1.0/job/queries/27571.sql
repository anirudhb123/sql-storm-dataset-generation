WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS kind,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2000
),
CompleteCasting AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        complete_cast cc
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        cc.movie_id
),
MovieDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.kind,
        cc.total_cast,
        cc.cast_names
    FROM 
        RankedTitles rt
    LEFT JOIN 
        CompleteCasting cc ON rt.title_id = cc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.kind,
    md.total_cast,
    md.cast_names,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = md.title_id) AS info_count,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = md.title_id) AS keyword_count
FROM 
    MovieDetails md
WHERE 
    md.total_cast IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title;
