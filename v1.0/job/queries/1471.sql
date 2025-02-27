WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 10
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_members
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalMovieMetrics AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(cd.total_cast, 0) AS total_cast,
        COALESCE(cd.cast_members, 'No Cast') AS cast_members,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        CastDetails cd ON tm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
)

SELECT 
    fmm.movie_id,
    fmm.title,
    fmm.production_year,
    fmm.total_cast,
    fmm.cast_members,
    fmm.keywords
FROM 
    FinalMovieMetrics fmm
WHERE 
    fmm.production_year >= 2000
ORDER BY 
    fmm.production_year DESC, 
    fmm.title ASC;
