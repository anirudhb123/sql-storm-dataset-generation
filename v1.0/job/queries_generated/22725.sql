WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        'High' AS cast_level
    FROM 
        RankedMovies
    WHERE 
        rank_per_year <= 5
),
LowCastMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        'Low' AS cast_level
    FROM 
        RankedMovies
    WHERE 
        cast_count < 3
),
SelectedMovies AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        h.cast_count,
        h.cast_level
    FROM 
        HighCastMovies h
    UNION ALL
    SELECT 
        l.movie_id,
        l.title,
        l.production_year,
        l.cast_count,
        l.cast_level
    FROM 
        LowCastMovies l
),
MovieDetails AS (
    SELECT 
        sm.movie_id,
        sm.title,
        sm.production_year,
        sm.cast_count,
        COALESCE(ci.note, 'No Role') AS role_note,
        string_agg(cc.kind, ', ') AS company_kinds,
        SUM(COALESCE(mi.info_type_id, 0)) AS info_type_sum
    FROM 
        SelectedMovies sm
    LEFT JOIN 
        complete_cast cc ON sm.movie_id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON sm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ci ON mc.company_type_id = ci.id
    LEFT JOIN 
        movie_info mi ON sm.movie_id = mi.movie_id
    GROUP BY 
        sm.movie_id, sm.title, sm.production_year, sm.cast_count, ci.note
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.role_note,
    md.company_kinds,
    CASE 
        WHEN md.info_type_sum > 10 THEN 'Rich Info'
        WHEN md.info_type_sum = 0 THEN 'No Info'
        ELSE 'Moderate Info'
    END AS info_richness,
    NULLIF(md.cast_count % 2, 0) AS odd_cast_count
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 1990 AND 2020
ORDER BY 
    md.production_year DESC, md.cast_count DESC;

