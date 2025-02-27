WITH RECURSIVE CompanyHierarchy AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        c.country_code,
        1 AS level
    FROM
        movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    WHERE
        c.country_code IS NOT NULL
        
    UNION ALL

    SELECT
        mc.movie_id,
        c.name AS company_name,
        c.country_code,
        ch.level + 1
    FROM
        movie_companies mc
    JOIN CompanyHierarchy ch ON mc.movie_id = ch.movie_id
    JOIN company_name c ON mc.company_id = c.id
    WHERE
        c.country_code IS NOT NULL
),
MovieCast AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM
        cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)

SELECT
    m.id AS movie_id,
    m.title,
    m.production_year,
    CASE 
        WHEN mh.level IS NOT NULL THEN mh.level 
        ELSE 0 
    END AS company_level,
    mc.actor_name,
    CASE 
        WHEN mk.keywords IS NULL THEN 'No keywords' 
        ELSE mk.keywords 
    END AS keywords
FROM
    title m
LEFT JOIN CompanyHierarchy mh ON m.id = mh.movie_id
LEFT JOIN MovieCast mc ON m.id = mc.movie_id
LEFT JOIN MovieKeywords mk ON m.id = mk.movie_id
WHERE
    m.production_year >= 2000
    AND (mh.company_name IS NULL OR mh.company_name LIKE '%Studio%')
ORDER BY
    m.production_year DESC,
    mc.actor_order;
