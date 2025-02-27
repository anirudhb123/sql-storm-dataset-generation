WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year,
        RM.title_rank,
        RM.cast_count
    FROM 
        RankedMovies RM
    WHERE 
        RM.cast_count > 5
),
MovieKeywords AS (
    SELECT 
        MK.movie_id,
        STRING_AGG(K.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword MK
    JOIN 
        keyword K ON MK.keyword_id = K.id
    GROUP BY 
        MK.movie_id
),
FinalResults AS (
    SELECT
        FM.movie_id,
        FM.title,
        FM.production_year,
        FM.title_rank,
        COALESCE(MK.keywords_list, 'No Keywords') AS keywords,
        CASE 
            WHEN FM.cast_count IS NULL THEN 'No Cast'
            WHEN FM.cast_count = 0 THEN 'Empty Cast'
            ELSE CAST(FM.cast_count AS TEXT)
        END AS cast_status
    FROM 
        FilteredMovies FM
    LEFT JOIN 
        MovieKeywords MK ON FM.movie_id = MK.movie_id
)
SELECT 
    FR.movie_id,
    FR.title,
    FR.production_year,
    FR.title_rank,
    FR.keywords,
    FR.cast_status,
    CASE 
        WHEN INSTR(FR.keywords, 'Action') > 0 THEN 'Action Movie'
        ELSE 'Other Genre'
    END AS genre_type
FROM 
    FinalResults FR
ORDER BY 
    FR.production_year DESC, 
    FR.title_rank ASC;
