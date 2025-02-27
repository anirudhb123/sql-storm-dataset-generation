WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.cast_count,
        rm.actor_names,
        rm.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY rm.production_year ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year IS NOT NULL AND 
        rm.cast_count >= 3
)

SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.actor_names,
    fm.keyword_count
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 5
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
