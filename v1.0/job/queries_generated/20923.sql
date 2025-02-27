WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_by_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL 
        AND a.title IS NOT NULL
), 
TopMovies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.rank_by_year
    FROM 
        RankedMovies r
    WHERE 
        r.rank_by_year <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(m.id) AS production_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.title, tm.production_year, k.keyword
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.keyword,
        md.production_count,
        DENSE_RANK() OVER (ORDER BY md.production_count DESC) AS production_rank
    FROM 
        MovieDetails md
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keyword,
    fr.production_count,
    fr.production_rank,
    CASE 
        WHEN fr.production_count = 0 THEN 'No Productions'
        WHEN fr.keyword IS NULL THEN 'Unknown Keyword'
        ELSE 'Produced'
    END AS production_status
FROM 
    FinalResults fr
WHERE 
    fr.production_rank <= 10
ORDER BY 
    fr.production_count DESC, 
    fr.title ASC;
