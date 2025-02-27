WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(NULLIF(t.production_year, 0), 'Unknown') AS production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rn <= 5
),
MovieDetails AS (
    SELECT 
        sm.movie_id,
        sm.title,
        sm.production_year,
        sm.cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        SelectedMovies sm
    JOIN 
        cast_info ci ON sm.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        sm.movie_id, sm.title, sm.production_year, sm.cast_count
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actors,
    mt.note AS movie_note
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info_idx mii ON md.movie_id = mii.movie_id
WHERE 
    it.info = 'rating' AND 
    cn.country_code IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
