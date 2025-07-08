
WITH movie_years AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast_members
    FROM aka_title mt
    LEFT JOIN complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE mt.production_year >= 2000
    GROUP BY mt.id, mt.title, mt.production_year
),
company_details AS (
    SELECT
        mc.movie_id,
        co.name AS company_name,
        ctype.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY co.name) AS company_rank
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ctype ON mc.company_type_id = ctype.id
),
keyword_info AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT
    my.movie_id,
    my.title,
    my.production_year,
    COALESCE(cd.company_name, 'Not Available') AS company_name,
    COALESCE(cd.company_type, 'Not Available') AS company_type,
    my.total_cast_members,
    ki.keywords
FROM movie_years my
LEFT JOIN company_details cd ON my.movie_id = cd.movie_id AND cd.company_rank = 1
LEFT JOIN keyword_info ki ON my.movie_id = ki.movie_id
WHERE my.total_cast_members > 5
ORDER BY my.production_year DESC, my.title ASC
LIMIT 100;
