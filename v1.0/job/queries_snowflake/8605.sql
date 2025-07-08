
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
), PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        pk.keyword,
        pk.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PopularKeywords pk ON rm.movie_id = pk.movie_id
    WHERE 
        rm.rank <= 5
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    LISTAGG(md.keyword, ', ') WITHIN GROUP (ORDER BY md.keyword) AS keywords
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_count
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
