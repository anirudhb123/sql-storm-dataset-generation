WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
), 
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
), 
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
        COALESCE(minfo.info, 'No Info') AS movie_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info minfo ON tm.movie_id = minfo.movie_id AND minfo.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
), 
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.movie_keyword,
        md.movie_info,
        ROW_NUMBER() OVER (ORDER BY md.production_year, md.title) AS final_rank
    FROM 
        MovieDetails md
)

SELECT 
    fr.*,
    COALESCE((SELECT AVG(rp.rating) 
              FROM ratings rp 
              WHERE rp.movie_id = fr.movie_id), 0) AS average_rating
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, 
    fr.final_rank;
