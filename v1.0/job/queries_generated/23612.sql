WITH Recursive MovieStats AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        COUNT(DISTINCT movie_keyword.keyword_id) AS total_keywords,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords_list,
        (SELECT COUNT(DISTINCT movie_link.linked_movie_id) 
         FROM movie_link 
         WHERE movie_link.movie_id = title.id) AS total_links,
        (SELECT AVG(CASE WHEN kind_type.kind = 'Feature' THEN 1 ELSE 0 END) 
         FROM aka_title 
         JOIN kind_type ON aka_title.kind_id = kind_type.id 
         WHERE aka_title.movie_id = title.id) AS feature_ratio
    FROM title
    LEFT JOIN cast_info ON title.id = cast_info.movie_id
    LEFT JOIN movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY title.id
),
DetailedStats AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.total_cast,
        ms.total_keywords,
        ms.keywords_list,
        ms.total_links,
        CASE 
            WHEN ms.total_cast > 0 THEN (CAST(ms.total_links AS FLOAT) / NULLIF(ms.total_cast, 0))
            ELSE NULL 
        END AS links_per_cast_member,
        ms.feature_ratio
    FROM MovieStats ms
),
RankedMovies AS (
    SELECT 
        ds.*,
        ROW_NUMBER() OVER (ORDER BY ds.total_cast DESC, ds.production_year ASC) AS rank_by_cast,
        RANK() OVER (ORDER BY ds.feature_ratio DESC NULLS LAST) AS rank_by_feature
    FROM DetailedStats ds
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.total_keywords,
    rm.keywords_list,
    rm.total_links,
    rm.links_per_cast_member,
    rm.rank_by_cast,
    rm.rank_by_feature
FROM RankedMovies rm
WHERE 
    (rm.rank_by_cast <= 10 OR rm.rank_by_feature <= 10)
    AND (rm.production_year IS NULL OR rm.production_year > 2000)
ORDER BY 
    rm.rank_by_cast,
    rm.rank_by_feature DESC;
