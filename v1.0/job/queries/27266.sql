
WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
),

MovieDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        kt.kind AS kind,
        COALESCE(COUNT(cc.id), 0) AS cast_count,
        COALESCE(GROUP_CONCAT(DISTINCT an.name), '') AS actor_names,
        COALESCE(GROUP_CONCAT(DISTINCT ki.keyword), '') AS keywords
    FROM RankedMovies rm
    LEFT JOIN complete_cast cc ON cc.movie_id = rm.title_id
    LEFT JOIN cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN aka_name an ON an.person_id = ci.person_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = rm.title_id
    LEFT JOIN keyword ki ON ki.id = mk.keyword_id
    LEFT JOIN kind_type kt ON kt.id = rm.kind_id
    GROUP BY rm.title_id, rm.title, rm.production_year, kt.kind
)

SELECT 
    md.title,
    md.production_year,
    md.kind,
    md.cast_count,
    md.actor_names,
    md.keywords
FROM MovieDetails md
WHERE md.cast_count > 5
ORDER BY md.production_year DESC, md.title;
