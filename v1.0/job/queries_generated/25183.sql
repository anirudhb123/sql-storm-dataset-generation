WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ka.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_title ka ON t.id = ka.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
GenreCounts AS (
    SELECT 
        k.kind AS genre,
        m.movie_id,
        COUNT(*) AS genre_count
    FROM 
        kind_type k
    JOIN 
        title t ON t.kind_id = k.id
    JOIN 
        complete_cast m ON t.id = m.movie_id
    GROUP BY 
        k.kind, m.movie_id
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.aka_names,
        md.keywords,
        COALESCE(SUM(gc.genre_count), 0) AS genre_distribution_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        GenreCounts gc ON md.movie_id = gc.movie_id
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.cast_count, md.aka_names, md.keywords
)
SELECT 
    rm.movie_id,
    rm.title, 
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    rm.keywords,
    rm.genre_distribution_count,
    ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.cast_count DESC) AS ranking
FROM 
    RankedMovies rm
WHERE 
    rm.production_year >= 2000 
    AND rm.cast_count > 5
ORDER BY 
    rm.genre_distribution_count DESC, rm.cast_count DESC;
