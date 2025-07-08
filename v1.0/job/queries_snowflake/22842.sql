
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year, a.id
),
PopularMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.total_cast,
        CASE 
            WHEN r.total_cast > 10 THEN 'Popular'
            ELSE 'Minor'
        END AS popularity
    FROM 
        RankedMovies r
    WHERE 
        r.year_rank <= 5
),
MovieDetails AS (
    SELECT 
        pm.title,
        pm.production_year,
        pm.popularity,
        (SELECT 
            COUNT(*) 
         FROM 
            movie_info mi 
         WHERE 
            mi.movie_id = pm.movie_id AND 
            mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')) AS genre_count,
        (SELECT 
            LISTAGG(kw.keyword, ', ') 
         FROM 
            movie_keyword mk 
         JOIN 
            keyword kw ON mk.keyword_id = kw.id 
         WHERE 
            mk.movie_id = pm.movie_id) AS keywords
    FROM 
        PopularMovies pm
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.popularity,
        md.genre_count,
        md.keywords,
        CASE 
            WHEN md.keywords IS NULL THEN 'No keywords'
            ELSE md.keywords
        END AS keyword_info,
        COALESCE(md.genre_count, 0) AS genre_information 
    FROM 
        MovieDetails md
    WHERE 
        md.production_year BETWEEN 2000 AND 2023
)

SELECT 
    fr.title,
    fr.production_year,
    fr.popularity,
    fr.genre_count,
    fr.keyword_info,
    CASE 
        WHEN fr.genre_count > 5 THEN 'Rich in genres'
        ELSE 'Limited genres'
    END AS genre_richness
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.title ASC
LIMIT 50;
