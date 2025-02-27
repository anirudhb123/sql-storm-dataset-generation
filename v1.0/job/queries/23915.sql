WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mci.note, 'No Company') AS company_note,
        COUNT(DISTINCT ci.id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_present_count,
        MAX(CASE WHEN ci.nr_order = 1 THEN ak.name END) AS main_actor,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_companies AS mci ON t.id = mci.movie_id
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, mci.note
),
HighCastMovies AS (
    SELECT 
        md.movie_id, 
        md.title, 
        md.production_year,
        md.cast_count,
        md.company_note,
        md.main_actor,
        md.all_actors,
        md.year_rank
    FROM 
        MovieDetails AS md
    WHERE 
        md.cast_count > 10
),
OldMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        title 
    WHERE 
        production_year < 1950
),
RankedMovies AS (
    SELECT 
        hcm.*, 
        om.title AS old_movie_title
    FROM 
        HighCastMovies hcm
    LEFT JOIN 
        OldMovies om ON hcm.title = om.title
)
SELECT 
    r.title AS high_cast_title,
    r.production_year,
    r.cast_count,
    r.company_note,
    r.main_actor,
    r.all_actors,
    CASE 
        WHEN r.old_movie_title IS NOT NULL THEN 'Related to an Old Movie'
        ELSE 'No Old Movie Reference'
    END AS movie_relationship,
    CASE 
        WHEN r.cast_count IS NULL THEN 'No Cast Info'
        ELSE 'Has Cast Info'
    END AS cast_info_status,
    r.year_rank
FROM 
    RankedMovies r
WHERE 
    r.year_rank <= 5  
ORDER BY 
    r.production_year DESC, 
    r.cast_count DESC;