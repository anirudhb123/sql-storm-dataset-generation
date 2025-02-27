
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),

TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.year_rank <= 5
),

MovieDetail AS (
    SELECT 
        mt.movie_id,
        mt.note,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        COUNT(DISTINCT ki.keyword) AS keyword_count,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        movie_companies mt
    LEFT JOIN 
        company_name c ON mt.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        complete_cast cc ON mt.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.id
    WHERE 
        mt.note IS NOT NULL
    GROUP BY 
        mt.movie_id, mt.note
),

FinalReport AS (
    SELECT 
        tt.title,
        tt.production_year,
        md.company_names,
        md.keyword_count,
        md.cast_count
    FROM 
        TopRankedTitles tt
    LEFT JOIN 
        MovieDetail md ON tt.title_id = md.movie_id
)

SELECT 
    fr.title,
    fr.production_year,
    COALESCE(fr.company_names, 'No Companies') AS companies,
    COALESCE(fr.keyword_count, 0) AS keyword_count,
    COALESCE(fr.cast_count, 0) AS cast_count
FROM 
    FinalReport fr
WHERE 
    fr.keyword_count > 1 OR fr.cast_count > 5
ORDER BY 
    fr.production_year DESC, fr.keyword_count DESC;
