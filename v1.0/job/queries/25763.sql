WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieCast AS (
    SELECT 
        r.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        RankedMovies r
    JOIN 
        complete_cast cc ON r.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        r.movie_id
),
FinalResults AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        mc.total_cast,
        mc.cast_names,
        STRING_AGG(DISTINCT r.keyword, ', ') AS keywords
    FROM 
        RankedMovies r
    JOIN 
        MovieCast mc ON r.movie_id = mc.movie_id
    WHERE 
        mc.total_cast > 5
    GROUP BY 
        r.movie_id, r.title, r.production_year, mc.total_cast, mc.cast_names
)
SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    cast_names,
    keywords
FROM 
    FinalResults
ORDER BY 
    production_year DESC,
    total_cast DESC;
