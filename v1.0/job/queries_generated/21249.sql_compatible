
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_per_year
    FROM title m
    WHERE m.production_year IS NOT NULL
),
ActorNames AS (
    SELECT 
        ak.person_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM aka_name ak
    GROUP BY ak.person_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        c.person_id,
        c.role_id,
        AN.actor_names,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    JOIN ActorNames AN ON c.person_id = AN.person_id
    LEFT JOIN role_type ri ON c.role_id = ri.id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rw.keyword_count,
        COALESCE(MIN(CASE WHEN kw.keyword LIKE '%action%' THEN 1 END), 0) AS has_action_keyword
    FROM RankedMovies rm
    LEFT JOIN MovieKeywordCounts rw ON rm.movie_id = rw.movie_id
    LEFT JOIN movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY rm.movie_id, rm.title, rw.keyword_count
)
SELECT 
    mwk.movie_id,
    mwk.title,
    rm.production_year,
    COALESCE(cd.actor_names, 'No Cast Available') AS actor_names,
    mwk.keyword_count,
    mwk.has_action_keyword,
    CASE 
        WHEN mwk.has_action_keyword = 1 THEN 'This movie includes action!'
        WHEN mwk.keyword_count > 5 THEN 'This movie has several keywords.'
        ELSE 'Keyword count is low.'
    END AS keyword_notes
FROM MoviesWithKeywords mwk
LEFT JOIN CastDetails cd ON mwk.movie_id = cd.movie_id
JOIN RankedMovies rm ON mwk.movie_id = rm.movie_id
WHERE rm.production_year >= 2000
ORDER BY rm.production_year DESC, mwk.title ASC
LIMIT 50;
