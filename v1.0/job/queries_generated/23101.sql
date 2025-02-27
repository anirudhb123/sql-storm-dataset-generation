WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_within_year
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    GROUP BY at.id, at.title, at.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM RankedMovies rm
    LEFT JOIN movie_keyword mk ON rm.title_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY rm.title_id, rm.title, rm.production_year, rm.cast_count
),
MoviesByStudio AS (
    SELECT 
        m.title_id,
        COALESCE(cn.name, 'Independent') AS studio_name,
        AVG(CASE WHEN mc.company_type_id IS NULL THEN NULL ELSE 1 END) AS average_rating,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COALESCE(cn.name, 'Independent')) AS studio_rank
    FROM MoviesWithKeywords m
    LEFT JOIN movie_companies mc ON m.title_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY m.title_id, cn.name
),
PopularTitles AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.cast_count,
        mw.keywords,
        ms.studio_name,
        ms.average_rating
    FROM MoviesWithKeywords mw
    JOIN MoviesByStudio ms ON mw.title_id = ms.title_id
    WHERE mw.cast_count > (
        SELECT AVG(cast_count) FROM RankedMovies
    )
),
ExtremeMovies AS (
    SELECT 
        pt.title,
        pt.production_year,
        pt.cast_count,
        pt.keywords,
        pt.studio_name,
        pt.average_rating,
        CASE 
            WHEN pt.cast_count > 10 THEN 'Star-Studded'
            WHEN pt.cast_count BETWEEN 5 AND 10 THEN 'Moderately Cast'
            ELSE 'Sparse Cast'
        END AS cast_quality,
        (CASE WHEN pt.average_rating IS NULL THEN 'No Rating' ELSE 'Rated' END) AS rating_status
    FROM PopularTitles pt
)
SELECT 
    em.title,
    em.production_year,
    em.cast_count,
    em.keywords,
    em.studio_name,
    em.average_rating,
    em.cast_quality,
    em.rating_status
FROM ExtremeMovies em
WHERE em.average_rating IS NOT NULL
ORDER BY em.production_year DESC, em.cast_count DESC
LIMIT 50;
