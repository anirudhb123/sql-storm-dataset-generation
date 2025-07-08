
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM
        aka_title a
    JOIN
        movie_keyword mk ON a.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.production_year >= 2000
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT CONCAT(n.name, ' as ', r.role), ', ') WITHIN GROUP (ORDER BY n.name) AS cast_list
    FROM
        cast_info ci
    JOIN
        name n ON ci.person_id = n.imdb_id
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        ci.movie_id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        cc.kind AS company_kind,
        ci.total_cast,
        ci.cast_list
    FROM
        aka_title m
    JOIN
        movie_companies mc ON m.id = mc.movie_id
    JOIN
        company_type cc ON mc.company_type_id = cc.id
    JOIN
        CastDetails ci ON m.id = ci.movie_id
    WHERE
        mc.note IS NULL
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mv.company_kind,
        mv.total_cast,
        mv.cast_list,
        COALESCE(COUNT(mk.id), 0) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieInfo mv ON rm.movie_id = mv.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    WHERE
        rm.rank = 1
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, mv.company_kind, mv.total_cast, mv.cast_list
    ORDER BY 
        rm.production_year DESC, mv.total_cast DESC
)

SELECT 
    *,
    CONCAT('Movie: ', title, ', Year: ', production_year, ', Cast: ', total_cast, ', Keywords: ', keyword_count) AS benchmark_info
FROM 
    FinalBenchmark
LIMIT 10;
