
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.company_id) AS production_company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM
        aka_title t
    JOIN
        movie_companies m ON t.id = m.movie_id
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name c ON ci.person_id = c.person_id
    GROUP BY
        t.id, t.title, t.production_year
),
RankedTitlesWithKeywords AS (
    SELECT
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.production_company_count,
        rt.cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        RankedTitles rt
    LEFT JOIN
        movie_keyword mk ON rt.title_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        rt.title_id, rt.title, rt.production_year,
        rt.production_company_count, rt.cast_names
),
FinalResults AS (
    SELECT
        r.title,
        r.production_year,
        r.production_company_count,
        r.cast_names,
        r.keywords,
        COALESCE(MAX(p.info), 'No additional info available') AS additional_info
    FROM
        RankedTitlesWithKeywords r
    LEFT JOIN
        movie_info mi ON r.title_id = mi.movie_id
    LEFT JOIN
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN
        person_info p ON mi.movie_id = p.person_id
    GROUP BY
        r.title, r.production_year, r.production_company_count, 
        r.cast_names, r.keywords
)
SELECT 
    title,
    production_year,
    production_company_count,
    cast_names,
    keywords,
    additional_info
FROM 
    FinalResults
WHERE
    production_company_count > 1
ORDER BY 
    production_year DESC, production_company_count DESC
LIMIT 50;
