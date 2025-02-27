WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_aka_names
    FROM 
        aka_title AS a
    JOIN 
        complete_cast AS cc ON a.movie_id = cc.movie_id
    JOIN 
        cast_info AS c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.kind_id, 
        rm.cast_count, 
        rm.all_aka_names,
        k.keyword
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        rm.production_year >= 2000 AND
        k.keyword LIKE '%action%'
),
FinalResults AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.kind_id,
        fm.cast_count,
        fm.all_aka_names,
        COUNT(DISTINCT mci.company_id) AS company_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_companies mci ON fm.movie_id = mci.movie_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year, fm.kind_id, fm.cast_count, fm.all_aka_names
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.all_aka_names,
    fr.company_count
FROM 
    FinalResults fr
ORDER BY 
    fr.cast_count DESC, 
    fr.production_year DESC
LIMIT 10;
