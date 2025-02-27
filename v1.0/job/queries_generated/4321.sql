WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS movie_rank,
        c.kind AS movie_kind
    FROM
        aka_title a
    JOIN
        cast_info b ON a.id = b.movie_id
    LEFT JOIN
        kind_type c ON a.kind_id = c.id
    WHERE
        b.nr_order IS NOT NULL
),
MovieDetails AS (
    SELECT
        rm.title,
        COALESCE(NULLIF(rm.movie_kind, ''), 'Unknown') AS kind,
        rm.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM
        RankedMovies rm
    LEFT JOIN
        cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
    LEFT JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        rm.movie_rank <= 5
    GROUP BY
        rm.title, rm.production_year, rm.movie_kind
),
MovieInfo AS (
    SELECT
        md.title,
        md.kind,
        md.production_year,
        md.total_cast,
        CASE 
            WHEN md.total_cast > 10 THEN 'Ensemble'
            WHEN md.total_cast BETWEEN 5 AND 10 THEN 'Moderate'
            ELSE 'Small' 
        END AS cast_size
    FROM
        MovieDetails md
    WHERE
        md.production_year BETWEEN 2000 AND 2020
),
FinalResults AS (
    SELECT
        mi.title,
        mi.kind,
        mi.production_year,
        mi.total_cast,
        mi.cast_size,
        ROW_NUMBER() OVER (ORDER BY mi.production_year DESC, mi.total_cast DESC) AS rank
    FROM
        MovieInfo mi
)
SELECT 
    fr.title,
    fr.kind,
    fr.production_year,
    fr.total_cast,
    fr.cast_size,
    fr.rank,
    CASE 
        WHEN fr.total_cast IS NULL THEN 'No Cast Info'
        ELSE 'Cast Listed'
    END AS cast_status
FROM 
    FinalResults fr
WHERE 
    fr.cast_size = 'Ensemble' OR fr.production_year = 2020
ORDER BY 
    fr.rank;
