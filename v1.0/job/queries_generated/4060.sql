WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) as rn
    FROM 
        aka_title t
    INNER JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
), MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        ct.kind,
        COALESCE(COUNT(ci.person_id), 0) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        kind_type ct ON rm.kind_id = ct.id
    GROUP BY 
        rm.title, rm.production_year, ct.kind
), FilteredMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.kind,
        md.cast_count,
        md.noted_cast_count
    FROM 
        MovieDetails md
    WHERE 
        (md.cast_count > 0 AND md.noted_cast_count * 1.0 / md.cast_count > 0.5)
        OR (md.production_year >= 2000 AND md.kind = 'feature')
)
SELECT 
    f.title,
    f.production_year,
    f.kind,
    f.cast_count,
    f.noted_cast_count,
    CONCAT(f.title, ' - ', f.production_year) AS title_year
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
