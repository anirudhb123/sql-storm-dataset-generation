WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
CharacterNames AS (
    SELECT
        cn.id AS char_id,
        cn.name,
        cn.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY cn.imdb_index ORDER BY cn.name) AS role_rank
    FROM
        char_name cn
    WHERE
        cn.name IS NOT NULL
),
MovieDetails AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mci.note, 'No Note') AS company_note,
        COUNT(mc.company_id) AS num_companies
    FROM
        aka_title mt
    LEFT JOIN
        movie_companies mc ON mc.movie_id = mt.movie_id
    LEFT JOIN
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN
        movie_info mi ON mi.movie_id = mt.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating' LIMIT 1)
    LEFT JOIN
        (SELECT id, movie_id, title FROM aka_title WHERE kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')) AS akat
    ON
        akat.movie_id = mt.movie_id
    LEFT JOIN
        complete_cast cc ON cc.movie_id = mt.movie_id
    LEFT JOIN
        aka_name an ON an.person_id = cc.subject_id
    LEFT JOIN
        RankedTitles rt ON rt.title_id = mt.id
    LEFT JOIN
        CharacterNames cn ON cn.imdb_index = rt.title_id
    GROUP BY
        mt.id, mt.title, mt.production_year, company_note
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.company_note,
    md.num_companies,
    COUNT(cc.subject_id) FILTER (WHERE cc.status_id = 1) AS active_cast_count,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = md.movie_id) AS keyword_count,
    MAX(CASE WHEN md.production_year >= 2000 THEN 'Modern' ELSE 'Classic' END) AS movie_era,
    ARRAY_AGG(DISTINCT cn.name ORDER BY cn.name) AS character_names
FROM
    MovieDetails md
LEFT JOIN
    complete_cast cc ON cc.movie_id = md.movie_id
LEFT JOIN
    aka_name an ON an.person_id = cc.subject_id
LEFT JOIN
    char_name ch ON ch.imdb_index = an.imdb_index
WHERE
    md.num_companies > 1 OR (md.num_companies = 1 AND md.company_note IS NOT NULL)
GROUP BY
    md.movie_id, md.title, md.production_year, md.company_note
ORDER BY
    md.production_year DESC, md.title ASC
LIMIT 100;

This SQL query accomplishes a complex analysis of movie details and cast information while leveraging various constructs, such as CTEs, window functions, outer joins, filtering, and aggregation. It also includes some nuanced conditions with NULL logic and uses correlated subqueries to derive additional insights, all while ensuring performance benchmarks through efficient grouping and ordering.
