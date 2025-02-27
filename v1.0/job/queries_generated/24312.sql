WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        COALESCE(mt.title, 'Unknown Title') AS movie_title,
        COALESCE(mt.production_year, 0) AS production_year,
        CASE
            WHEN mt.production_year IS NULL THEN 'Unreleased'
            WHEN mt.production_year < 2000 THEN 'Pre-2000'
            ELSE 'Post-2000'
        END AS release_category,
        mn.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank,
        MAX(CASE WHEN k.keyword IS NOT NULL THEN k.keyword ELSE 'No Keywords' END) OVER (PARTITION BY m.id) AS keyword_summary
    FROM aka_title mt
    LEFT JOIN movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id AND (cn.country_code IS NOT NULL OR cn.name IS NOT NULL)
    LEFT JOIN cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN aka_name mn ON ci.person_id = mn.person_id AND mn.name IS NOT NULL
    LEFT JOIN movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    JOIN title m ON mt.id = m.id
    WHERE cn.name IS NOT NULL OR ci.role_id IS NOT NULL
    UNION ALL
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.release_category,
        CASE
            WHEN mh.director_name IS NOT NULL THEN mh.director_name
            ELSE 'Unknown Director'
        END AS director_name,
        mh.year_rank,
        mh.keyword_summary
    FROM MovieHierarchy mh
    WHERE mh.production_year IS NOT NULL
),
AggregatedResults AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        release_category,
        director_name,
        year_rank,
        keyword_summary,
        COUNT(*) FILTER (WHERE director_name IS NOT NULL) AS director_count
    FROM MovieHierarchy
    GROUP BY
        movie_id, movie_title, production_year, release_category, director_name, year_rank, keyword_summary
    HAVING
        COUNT(*) > 1
)
SELECT
    ar.movie_id,
    ar.movie_title,
    ar.production_year,
    ar.release_category,
    ar.director_name,
    ar.year_rank,
    ar.keyword_summary,
    COALESCE(STRING_AGG(DISTINCT ar.director_name, ', '), 'No Directors') AS consolidated_directors
FROM AggregatedResults ar
LEFT JOIN movie_info mi ON ar.movie_id = mi.movie_id AND mi.info_type_id IN (
    SELECT id FROM info_type WHERE info LIKE '%award%'
)
GROUP BY
    ar.movie_id, ar.movie_title, ar.production_year, ar.release_category, ar.director_name, ar.year_rank, ar.keyword_summary
ORDER BY
    ar.production_year DESC,
    ar.year_rank;
