WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ARRAY[t.title] AS title_path,
        1 AS depth
    FROM title t
    WHERE t.season_nr IS NULL
    
    UNION ALL
    
    SELECT 
        mt.linked_movie_id, 
        tt.title, 
        tt.production_year, 
        mh.title_path || tt.title,
        mh.depth + 1
    FROM movie_link mt
    JOIN title tt ON mt.linked_movie_id = tt.id
    JOIN MovieHierarchy mh ON mt.movie_id = mh.movie_id
),
KeywordRanking AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY mk.movie_id ORDER BY COUNT(mk.keyword_id) DESC) AS keyword_rank
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id, k.keyword
),
ExtendedCast AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE a.name IS NOT NULL
),
MovieInfoWithKeywords AS (
    SELECT 
        mi.movie_id,
        mi.info,
        STRING_AGG(DISTINCT kr.keyword, ', ') AS keywords
    FROM movie_info mi
    LEFT JOIN KeywordRanking kr ON mi.movie_id = kr.movie_id AND kr.keyword_rank <= 3
    GROUP BY mi.movie_id, mi.info
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ec.actor_name,
    miw.info,
    miw.keywords,
    COUNT(DISTINCT ec.actor_name) AS distinct_actors,
    SUM(CASE WHEN ec.total_cast > 10 THEN 1 ELSE 0 END) AS high_cast_count,
    CASE 
        WHEN mh.depth > 1 THEN 'Part of Series'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM MovieHierarchy mh
LEFT JOIN ExtendedCast ec ON mh.movie_id = ec.movie_id
LEFT JOIN MovieInfoWithKeywords miw ON mh.movie_id = miw.movie_id
WHERE mh.production_year > 2000
GROUP BY mh.movie_id, mh.title, mh.production_year, ec.actor_name, miw.info, miw.keywords, mh.depth
ORDER BY mh.production_year DESC, cnt_actors DESC
LIMIT 50;
