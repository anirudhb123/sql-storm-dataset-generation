WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvMovie'))
),
CastStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(ni.gender) AS lead_gender
    FROM 
        cast_info ci
    JOIN 
        name ni ON ci.person_id = ni.id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    RM.movie_id,
    RM.title,
    RM.production_year,
    COALESCE(CS.total_cast, 0) AS total_cast,
    COALESCE(CS.lead_gender, 'Unknown') AS lead_gender,
    COALESCE(MK.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN RM.title_rank = 1 THEN 'First Movie of Year'
        WHEN RM.title_rank = 2 THEN 'Second Movie of Year'
        ELSE 'Other Movie'
    END AS rank_description
FROM 
    RankedMovies RM
LEFT JOIN 
    CastStats CS ON RM.movie_id = CS.movie_id
LEFT JOIN 
    MovieKeywords MK ON RM.movie_id = MK.movie_id
WHERE 
    RM.production_year >= 2000
ORDER BY 
    RM.production_year DESC, 
    RM.title;
