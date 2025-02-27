WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(mn.name, ', ' ORDER BY mn.name) AS all_actors
    FROM 
        movie_keyword mk
    JOIN 
        movie_companies mc ON mk.movie_id = mc.movie_id
    JOIN 
        title mt ON mt.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mt.id
    LEFT JOIN 
        aka_name mn ON mn.person_id = ci.person_id
    GROUP BY 
        mt.movie_id
),
StatusInfo AS (
    SELECT 
        COMPLETE.id AS complete_cast_id,
        C.id AS cast_info_id,
        C.note AS cast_note,
        ABS(EXTRACT(YEAR FROM CURRENT_DATE) - T.production_year) AS age_difference
    FROM 
        complete_cast COMPLETE
    JOIN 
        title T ON COMPLETE.movie_id = T.id
    JOIN 
        cast_info C ON C.movie_id = T.id
    WHERE 
        COMPLETE.status_id = (
            SELECT 
                MAX(status_id) 
            FROM 
                complete_cast 
            WHERE 
                movie_id = COMPLETE.movie_id
        )
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(md.keyword_count, 0) AS total_keywords,
    COALESCE(si.cast_note, 'No Notes') AS last_cast_note,
    CASE 
        WHEN si.age_difference < 1 THEN 'New Release'
        WHEN si.age_difference BETWEEN 1 AND 5 THEN 'Recent'
        ELSE 'Classic'
    END AS release_category,
    COUNT(DISTINCT si.complete_cast_id) AS total_complete_casts,
    STRING_AGG(DISTINCT si.cast_note, '; ') AS all_cast_notes
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieDetails md ON rt.title_id = md.movie_id
LEFT JOIN 
    StatusInfo si ON si.complete_cast_id IS NOT NULL 
GROUP BY 
    rt.title_id, rt.production_year, md.keyword_count, si.cast_note
HAVING 
    COUNT(DISTINCT si.cast_note) > 1 OR md.keyword_count > 1
ORDER BY 
    rt.production_year DESC, total_keywords DESC;
