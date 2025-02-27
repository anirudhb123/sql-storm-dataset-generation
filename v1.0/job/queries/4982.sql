WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mc.total_cast, 0) AS total_cast,
        COALESCE(mk.keyword_count, 0) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_rank
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieCast mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.total_cast,
    fr.keyword_count,
    fr.year_rank,
    CASE 
        WHEN fr.keyword_count > 10 THEN 'High Keyword'
        WHEN fr.total_cast > 20 THEN 'Ensemble Cast' 
        ELSE 'Regular Movie'
    END AS movie_category
FROM 
    FinalResults fr
WHERE 
    (fr.keyword_count >= 5 OR fr.total_cast IS NOT NULL)
ORDER BY 
    fr.production_year DESC, fr.title;
