WITH RECURSIVE movie_hierarchy AS (
    -- CTE to find all movies along with their direct and indirect linkages
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        1 AS depth
    FROM
        movie_link ml
    UNION ALL
    SELECT
        mh.movie_id,
        ml.linked_movie_id,
        mh.depth + 1
    FROM
        movie_hierarchy mh
    JOIN
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    WHERE
        mh.depth < 3  -- Limit to depth 3 for performance benchmarking
),
movie_cast AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM
        cast_info ci
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
),
movie_info_details AS (
    SELECT
        mi.movie_id,
        MAX(mi.info) AS most_recent_info,
        COUNT(DISTINCT mi.info_type_id) AS info_type_count
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
),
movie_company_count AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS companies_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
)
SELECT
    t.title,
    t.production_year,
    mh.linked_movie_id,
    COALESCE(mc.companies_count, 0) AS companies_count,
    COALESCE(mcd.cast_count, 0) AS cast_count,
    COALESCE(mcd.actor_names, 'No Actors') AS actor_names,
    COALESCE(mid.most_recent_info, 'No Info') AS most_recent_info,
    CASE 
        WHEN mc.companies_count IS NULL AND mcd.cast_count IS NULL THEN 'Unknown Movie'
        WHEN mid.info_type_count > 2 THEN 'Rich Info'
        ELSE 'Standard Info'
    END AS info_richness
FROM
    title t
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.movie_id
LEFT JOIN
    movie_company_count mc ON mh.linked_movie_id = mc.movie_id
LEFT JOIN
    movie_cast mcd ON mh.linked_movie_id = mcd.movie_id
LEFT JOIN
    movie_info_details mid ON mh.linked_movie_id = mid.movie_id
WHERE
    t.production_year > 2000
    AND (t.kind_id IS NOT NULL OR mh.linked_movie_id IS NOT NULL)
ORDER BY
    t.production_year DESC,
    mcd.cast_count DESC NULLS LAST,
    mc.companies_count ASC NULLS FIRST
LIMIT 100;
