WITH ranked_movies AS (
    SELECT
        mt.title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS rank_by_year,
        COUNT(*) OVER (PARTITION BY mt.kind_id) AS total_in_kind
    FROM
        aka_title mt
    JOIN
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Sci-Fi%')
),
movie_details AS (
    SELECT
        rm.title,
        rm.production_year,
        c.name AS company_name,
        ARRAY_AGG(DISTINCT cn.name) AS character_names,
        ROW_NUMBER() OVER (PARTITION BY rm.kind_id ORDER BY rm.production_year DESC) AS title_rank,
        MAX(CASE WHEN p.gender IS NULL THEN 'Unknown' ELSE p.gender END) AS gender_info
    FROM
        ranked_movies rm
    LEFT JOIN
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN
        company_name c ON mc.company_id = c.id
    LEFT JOIN
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN
        char_name cn ON cc.subject_id = cn.id
    LEFT JOIN
        name p ON cc.person_id = p.imdb_id
    GROUP BY
        rm.title, rm.production_year, c.name, rm.kind_id
),
movie_info_filtered AS (
    SELECT
        md.title,
        md.production_year,
        md.company_name,
        md.character_names,
        md.gender_info
    FROM
        movie_details md
    WHERE
        md.production_year > 2000 AND
        md.gender_info IS NOT NULL
),
final_result AS (
    SELECT
        mif.title,
        mif.production_year,
        mif.company_name,
        COALESCE(mif.character_names::text, 'No Characters') AS character_names,
        ROW_NUMBER() OVER (ORDER BY mif.production_year DESC, mif.company_name) AS display_order
    FROM
        movie_info_filtered mif
    WHERE
        mif.company_name IS NOT NULL
    ORDER BY
        mif.production_year DESC, mif.company_name
)
SELECT
    f.title,
    f.production_year,
    f.company_name,
    f.character_names,
    CASE WHEN f.display_order < 10 THEN 'Top Ten' ELSE 'Beyond Top Ten' END AS ranking_category
FROM
    final_result f
WHERE
    f.character_names IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = f.title)
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
    )
ORDER BY
    f.production_year DESC, f.company_name;
