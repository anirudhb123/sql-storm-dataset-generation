WITH RecursiveMovieInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COALESCE(c.info, 'No Info') AS additional_info,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year IS NOT NULL 
        AND (it.info IS NOT NULL OR k.keyword IS NOT NULL)
),
FilteredMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY production_year ORDER BY title) AS year_rank
    FROM 
        RecursiveMovieInfo
    WHERE 
        keyword_rank < 3  -- Considering only the first two keywords
),
FinalOutput AS (
    SELECT 
        fm.title_id,
        fm.title,
        fm.production_year,
        COUNT(DISTINCT fm.keyword) AS keyword_count,
        STRING_AGG(DISTINCT fm.keyword, ', ') AS keywords,
        MAX(CASE WHEN fm.additional_info IS NOT NULL THEN fm.additional_info ELSE 'No Info Available' END) AS collected_info
    FROM 
        FilteredMovies fm
    GROUP BY 
        fm.title_id, fm.title, fm.production_year
    HAVING 
        keyword_count > 0 
        AND MAX(CASE WHEN fm.additional_info IS NULL THEN 1 ELSE 0 END) = 0
)
SELECT 
    fo.title_id,
    fo.title,
    fo.production_year,
    fo.keyword_count,
    fo.keywords,
    fo.collected_info
FROM 
    FinalOutput fo
LEFT JOIN 
    aka_name an ON an.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = fo.title_id)
WHERE 
    an.name IS NOT NULL
ORDER BY 
    fo.production_year DESC, 
    fo.keyword_count DESC
LIMIT 100;

