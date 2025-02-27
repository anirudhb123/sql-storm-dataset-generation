WITH MovieCharacterCount AS (
    SELECT
        at.id AS title_id,
        at.title AS movie_title,
        COUNT(ci.id) AS character_count
    FROM
        aka_title at
    INNER JOIN
        complete_cast cc ON at.id = cc.movie_id
    INNER JOIN
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY
        at.id, at.title
),
MovieKeywordInfo AS (
    SELECT
        mk.movie_id,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    INNER JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
PersonDetails AS (
    SELECT
        an.id AS name_id,
        an.name AS person_name,
        ai.note AS info_note,
        ai.info AS biography
    FROM
        aka_name an
    LEFT JOIN
        person_info ai ON ai.person_id = an.person_id
),
MovieCompanyInfo AS (
    SELECT
        mc.movie_id,
        string_agg(cn.name, ', ') AS companies,
        string_agg(ct.kind, ', ') AS company_types
    FROM
        movie_companies mc
    INNER JOIN
        company_name cn ON mc.company_id = cn.id
    INNER JOIN
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    mt.title_id,
    mt.movie_title,
    mt.character_count,
    mk.keywords,
    pc.person_name,
    pc.biography,
    mc.companies,
    mc.company_types
FROM
    MovieCharacterCount mt
LEFT JOIN
    MovieKeywordInfo mk ON mt.title_id = mk.movie_id
LEFT JOIN
    PersonDetails pc ON mt.title_id = pc.name_id
LEFT JOIN
    MovieCompanyInfo mc ON mt.title_id = mc.movie_id
WHERE
    mt.character_count > 0
ORDER BY
    mt.character_count DESC,
    mt.movie_title ASC;
