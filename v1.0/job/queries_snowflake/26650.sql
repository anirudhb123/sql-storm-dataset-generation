
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM aka_title a
    WHERE a.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        kt.kind AS kind,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS cast_names
    FROM RankedMovies rm
    JOIN title t ON rm.movie_id = t.id
    JOIN movie_companies mc ON rm.movie_id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN kind_type kt ON t.kind_id = kt.id
    LEFT JOIN cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN aka_name an ON ci.person_id = an.person_id
    GROUP BY rm.movie_id, rm.title, rm.production_year, kt.kind
),
FilteredMovies AS (
    SELECT 
        md.*,
        MIN(md.production_year) OVER (PARTITION BY md.kind) AS min_year_for_kind
    FROM MovieDetails md
    WHERE md.company_count > 2
)
SELECT 
    fm.title,
    fm.production_year,
    fm.kind,
    fm.company_count,
    fm.min_year_for_kind,
    fm.cast_names
FROM FilteredMovies fm
ORDER BY fm.production_year DESC, fm.company_count DESC;
