
WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mc.note IS NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.keywords,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.cast_count DESC) AS popular_rank
    FROM 
        MovieDetails md
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.keywords,
    rt.rank AS keyword_rank
FROM 
    TopMovies tm
LEFT JOIN 
    RankedTitles rt ON tm.title = rt.title AND tm.production_year = rt.production_year
WHERE 
    tm.popular_rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
