
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        mv.movie_id,
        mv.title,
        COALESCE(COUNT(DISTINCT cc.id), 0) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names, 
        COALESCE(SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_count
    FROM 
        RankedMovies mv
    LEFT JOIN 
        cast_info cc ON mv.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    LEFT JOIN 
        movie_info mi ON mv.movie_id = mi.movie_id
    GROUP BY 
        mv.movie_id, mv.title
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.cast_count,
        md.cast_names,
        COALESCE(SUM(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_count,
        ROW_NUMBER() OVER (ORDER BY md.cast_count DESC) AS top_rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_info mi ON md.movie_id = mi.movie_id
    WHERE 
        md.cast_count > 5
    GROUP BY 
        md.movie_id, md.title, md.cast_count, md.cast_names
)

SELECT 
    tm.title AS "Top Movie Title",
    tm.cast_count AS "Number of Cast Members",
    tm.cast_names AS "Cast Members",
    CASE 
        WHEN tm.info_count > 10 THEN 'Rich Info'
        ELSE 'Basic Info'
    END AS "Info Quality"
FROM 
    TopMovies tm
WHERE 
    tm.top_rank <= 10
ORDER BY 
    tm.cast_count DESC, 
    tm.title;
