WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS rn
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(rm.keyword, ', ') AS keyword_list
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5  -- Top 5 keywords per movie
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
CastDetails AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword_list,
        cd.cast_names,
        cd.cast_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    fb.title,
    fb.production_year,
    fb.keyword_list,
    fb.cast_names,
    fb.cast_count
FROM 
    FinalBenchmark fb
WHERE 
    fb.cast_count > 0
ORDER BY 
    fb.production_year DESC, 
    fb.title;
