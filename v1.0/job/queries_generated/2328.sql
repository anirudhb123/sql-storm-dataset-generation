WITH RankedMovies AS (
    SELECT 
        title.title, 
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM title
    JOIN cast_info ON title.id = cast_info.movie_id
    GROUP BY title.title, title.production_year
),
MoviesWithKeywords AS (
    SELECT 
        r.title, 
        r.production_year,
        k.keyword,
        COALESCE(mi.info, 'No Info') AS additional_info
    FROM RankedMovies r
    LEFT JOIN movie_keyword mk ON r.title = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info mi ON r.title = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary' LIMIT 1)
    WHERE r.rank <= 5
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS comp_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
)
SELECT 
    mwk.title,
    mwk.production_year,
    mwk.keyword,
    mwk.additional_info,
    COALESCE(cc.comp_count, 0) AS company_count
FROM MoviesWithKeywords mwk
LEFT JOIN CompanyCount cc ON mwk.title = cc.movie_id
ORDER BY mwk.production_year DESC, mwk.num_cast DESC, mwk.title;
