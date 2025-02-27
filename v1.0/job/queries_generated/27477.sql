WITH RankedTitles AS (
    SELECT
        at.title,
        at.production_year,
        ak.name AS actor_name,
        rk.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM aka_title at
    JOIN cast_info ci ON at.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type rk ON ci.role_id = rk.id
    WHERE at.production_year > 2000
),

MovieKeywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN aka_title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
),

MovieInfoDetails AS (
    SELECT
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_details
    FROM movie_info mi
    GROUP BY mi.movie_id
)

SELECT
    rt.title,
    rt.production_year,
    rt.actor_name,
    rt.role_name,
    mk.keywords,
    mid.info_details
FROM RankedTitles rt
LEFT JOIN MovieKeywords mk ON rt.id = mk.movie_id
LEFT JOIN MovieInfoDetails mid ON rt.id = mid.movie_id
WHERE rt.actor_rank <= 3
ORDER BY rt.production_year DESC, rt.title ASC;
