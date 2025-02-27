WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS year_title_count
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
PersonInfo AS (
    SELECT
        pi.person_id,
        STRING_AGG(DISTINCT pi.info, ', ') AS person_info
    FROM
        person_info pi
    GROUP BY
        pi.person_id
),
CastRoles AS (
    SELECT
        ci.movie_id,
        ci.role_id,
        COUNT(*) AS role_count
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id, ci.role_id
    HAVING
        COUNT(*) > 1
),
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        COALESCE(t.production_year, 'Unknown') AS production_year,
        ti.keywords,
        ci.role_id,
        cr.role_count,
        CASE
            WHEN cr.role_count IS NULL THEN 'No Roles'
            ELSE 'Has Roles'
        END AS role_status
    FROM
        title t
    LEFT JOIN 
        TitleKeywords ti ON t.id = ti.movie_id
    LEFT JOIN 
        CastRoles cr ON t.id = cr.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.role_status,
    pi.person_info
FROM 
    MovieDetails md
LEFT JOIN 
    (SELECT DISTINCT ci.movie_id, 
                     STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
     FROM 
        cast_info ci
     JOIN 
        aka_name ak ON ci.person_id = ak.person_id
     GROUP BY 
        ci.movie_id) AS CastList ON md.movie_id = CastList.movie_id
LEFT JOIN 
    PersonInfo pi ON pi.person_id IN (SELECT DISTINCT ci.person_id 
                                       FROM cast_info ci WHERE ci.movie_id = md.movie_id)
WHERE 
    md.production_year <> 'Unknown' 
    AND (md.role_status = 'Has Roles' OR md.keywords IS NOT NULL)
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
