WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        kc.kind AS kind,
        COALESCE(SUM(CASE WHEN co.kind = 'Production' THEN 1 ELSE 0 END), 0) AS production_count,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM
        title t
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_type co ON mc.company_type_id = co.id
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        kind_type kc ON t.kind_id = kc.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year, kc.kind
),
top_movies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind,
        rm.production_count,
        rm.cast_count,
        rm.rank
    FROM
        ranked_movies rm
    WHERE
        rm.rank <= 5
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.kind,
    tm.production_count,
    tm.cast_count,
    ak.name AS main_actor_name,
    ak.name_pcode_nf AS actor_pcode_nf,
    ak.md5sum AS actor_md5sum
FROM
    top_movies tm
LEFT JOIN
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
WHERE
    ak.name IS NOT NULL
ORDER BY
    tm.production_year DESC, tm.cast_count DESC;
