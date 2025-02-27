WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        c.id AS person_id,
        ak.name AS aka_name,
        ci.nr_order,
        DENSE_RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        name c ON ak.person_id = c.imdb_id
),
MoviesWithCast AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        cd.aka_name,
        cd.nr_order,
        cd.role_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.title_id = cd.movie_id
),
GenreInfo AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT gt.kind, ', ') AS genres
    FROM 
        movie_companies mt
    JOIN 
        company_type ct ON mt.company_type_id = ct.id
    JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id 
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'genre')
    GROUP BY 
        mt.movie_id
)
SELECT 
    mwc.title,
    mwc.production_year,
    COALESCE(mwc.aka_name, 'Unknown') AS actor_name,
    MAX(mwc.role_rank) AS highest_role_rank,
    gi.genres,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mwc.title_id) AS keyword_count
FROM 
    MoviesWithCast mwc
LEFT JOIN 
    GenreInfo gi ON mwc.title_id = gi.movie_id
WHERE 
    mwc.production_year >= 2000
GROUP BY 
    mwc.title_id, mwc.title, mwc.production_year, gi.genres
HAVING 
    COUNT(mwc.aka_name) > 1 
    AND MAX(mwc.role_rank) IS NOT NULL
ORDER BY 
    mwc.production_year DESC, 
    keyword_count DESC NULLS LAST;

-- corner cases: checking for NULL handling, ensuring correct order, 
-- coalescing unknown actor names, using HAVING to filter on 
-- aggregate results while considering NULL logic.
