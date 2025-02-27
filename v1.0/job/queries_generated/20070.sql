WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        COALESCE(SUM(mci.company_id), 0) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    GROUP BY 
        mt.id
    HAVING 
        COUNT(mci.company_id) > 0
    UNION ALL
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year,
        mc.company_id
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id 
    WHERE 
        mc.note IS NULL
),
CharacterRoleCount AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) FILTER (WHERE ci.person_role_id IS NOT NULL) AS actor_count
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order IS NOT NULL
    GROUP BY 
        ci.movie_id
),
TitleWithEmptyNames AS (
    SELECT 
        at.id AS title_id,
        at.title,
        CASE 
            WHEN ak.name IS NULL THEN 'No Name Available' 
            ELSE ak.name 
        END AS name_or_default
    FROM 
        aka_title at
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (
            SELECT DISTINCT ci.person_id 
            FROM cast_info ci WHERE ci.movie_id = at.id
        )
),
KeywordGroup AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(mk.keyword, ', ' ORDER BY mk.keyword) AS keywords
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rmc.movie_id,
    rmc.title,
    rmc.production_year,
    COALESCE(crc.actor_count, 0) AS actor_count,
    COALESCE(kd.keywords, 'No Keywords') AS keywords,
    'Produced by ' || COALESCE(CAST(rmc.company_count AS TEXT), 'No Companies') AS production_details,
    twn.name_or_default
FROM 
    RecursiveMovieCTE rmc
LEFT JOIN 
    CharacterRoleCount crc ON rmc.movie_id = crc.movie_id
LEFT JOIN 
    KeywordGroup kd ON rmc.movie_id = kd.movie_id
LEFT JOIN 
    TitleWithEmptyNames twn ON rmc.movie_id = twn.title_id
WHERE 
    rmc.production_year BETWEEN 2000 AND 2023 
    AND (crc.actor_count IS NULL OR crc.actor_count > 3)
ORDER BY 
    rmc.production_year DESC NULLS LAST,
    rmc.title ASC;
