WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_year
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(STRING_AGG(DISTINCT c.name, ', '), 'No Cast') AS cast_names,
        COALESCE(STRING_AGG(DISTINCT co.name, ', '), 'No Companies') AS company_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count,
        COUNT(DISTINCT ci.id) AS complete_cast_count
    FROM
        aka_title m
    LEFT JOIN
        cast_info ci ON ci.movie_id = m.id
    LEFT JOIN
        aka_name c ON c.person_id = ci.person_id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN
        company_name co ON co.id = mc.company_id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY
        m.id
),
FinalReport AS (
    SELECT
        dt.title,
        dt.production_year,
        dt.cast_names,
        dt.company_names,
        dt.keyword_count,
        dt.complete_cast_count,
        CASE 
            WHEN dt.production_year < 1990 THEN 'Classic'
            WHEN dt.production_year BETWEEN 1990 AND 2000 THEN '90s'
            ELSE 'Modern'
        END AS era,
        (CASE
             WHEN dt.keyword_count IS NULL THEN 'No Keywords'
             WHEN dt.keyword_count > 10 THEN 'Highly Keyworded'
             ELSE 'Low Keyword Count'
         END) AS keyword_status
    FROM
        MovieDetails dt
    WHERE
        dt.complete_cast_count > 0
    ORDER BY
        dt.production_year DESC, dt.title
)
SELECT 
    fr.title,
    fr.production_year,
    fr.cast_names,
    fr.company_names,
    fr.keyword_count,
    fr.era,
    fr.keyword_status,
    RT.title AS related_title
FROM 
    FinalReport fr
LEFT JOIN 
    RankedTitles RT ON fr.production_year = RT.production_year AND fr.title <> RT.title AND RT.rank_by_year <= 5
WHERE 
    (fr.keyword_count > 0 OR fr.cast_names IS NOT NULL)
ORDER BY 
    fr.production_year DESC, fr.title;
