WITH RecursiveNames AS (
    SELECT
        a.id AS aka_id,
        a.name,
        a.person_id,
        a.md5sum AS aka_md5sum
    FROM aka_name a
    WHERE a.name IS NOT NULL

    UNION ALL

    SELECT
        c.id AS char_id,
        c.name,
        c.imdb_id,
        c.md5sum AS char_md5sum
    FROM char_name c
    JOIN RecursiveNames rn ON c.imdb_index = rn.name_pcode_nf
),

PopularTitles AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count
    FROM aka_title at
    JOIN cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY at.title, at.production_year
    HAVING COUNT(ci.id) > 5
),

DetailedMovieInfo AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        GROUP_CONCAT(DISTINCT ci.person_id) AS cast_ids,
        GROUP_CONCAT(DISTINCT ki.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM aka_title at
    JOIN cast_info ci ON ci.movie_id = at.movie_id
    LEFT JOIN movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN movie_companies mc ON mc.movie_id = at.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY at.id, at.title, at.production_year
),

FinalOutput AS (
    SELECT 
        dni.aka_id,
        dni.name AS actor_name,
        dmi.title,
        dmi.production_year,
        dmi.cast_ids,
        dmi.keywords,
        dmi.company_types
    FROM RecursiveNames dni
    JOIN DetailedMovieInfo dmi ON dni.person_id = dmi.cast_ids
    WHERE dni.aka_md5sum IS NOT NULL
)

SELECT *
FROM FinalOutput
ORDER BY production_year DESC, actor_name;
