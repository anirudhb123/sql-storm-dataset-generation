WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCounts AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TitleKeywordCounts AS (
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
FullMovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(cc.company_count, 0) AS company_count,
        COALESCE(tkc.keyword_count, 0) AS keyword_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        CompanyCounts cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        TitleKeywordCounts tkc ON m.movie_id = tkc.movie_id
)
SELECT 
    fmd.title,
    fmd.production_year,
    fmd.company_count,
    fmd.keyword_count,
    COALESCE((
        SELECT 
            COUNT(DISTINCT ci.id)
        FROM 
            cast_info ci
        WHERE 
            ci.movie_id = fmd.movie_id AND 
            ci.note IS NULL
    ), 0) AS null_cast_count
FROM 
    FullMovieDetails fmd
WHERE 
    fmd.company_count > 1 AND 
    fmd.keyword_count >= 2
ORDER BY 
    fmd.production_year DESC, 
    fmd.company_count DESC
LIMIT 100;
