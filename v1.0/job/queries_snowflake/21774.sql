
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, LENGTH(a.title)) AS rank_per_year
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
MovieActors AS (
    SELECT 
        m.title,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        COUNT(DISTINCT ak.person_id) AS actor_count
    FROM aka_title m
    JOIN cast_info ci ON m.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY m.title
),
KeywordMovies AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN aka_title m ON mk.movie_id = m.id
    GROUP BY m.id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(MAX(mi.info), 'No Info') AS info_summary
    FROM aka_title m
    LEFT JOIN movie_info mi ON mi.movie_id = m.id
    GROUP BY m.id
)
SELECT 
    rm.title,
    rm.production_year,
    ma.actors,
    ma.actor_count,
    km.keywords,
    mi.info_summary
FROM RankedMovies rm
LEFT JOIN MovieActors ma ON rm.title = ma.title
LEFT JOIN KeywordMovies km ON rm.rank_per_year = km.movie_id
LEFT JOIN MovieInfo mi ON rm.production_year = mi.movie_id
WHERE rm.rank_per_year <= 5 
AND (ma.actor_count > 1 OR mi.info_summary IS NOT NULL)
ORDER BY rm.production_year DESC, ma.actor_count DESC, rm.title;
