WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
        LEFT JOIN cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
TopRankedMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 3
),
MovieKeywords AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title at
        JOIN movie_keyword mk ON at.movie_id = mk.movie_id
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id
)
SELECT 
    tr.title,
    tr.production_year,
    tr.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(mci.name, 'Unknown Company') AS production_company
FROM 
    TopRankedMovies tr
    LEFT JOIN movie_companies mc ON tr.production_year = mc.movie_id
    LEFT JOIN company_name mci ON mc.company_id = mci.id
    LEFT JOIN MovieKeywords mk ON tr.title = mk.title
WHERE 
    tr.cast_count > 0
ORDER BY 
    tr.production_year DESC, tr.cast_count DESC;

