WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank 
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        SUM(CASE 
            WHEN mi.info IS NULL THEN 0 
            ELSE 1 
        END) AS info_count 
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = tm.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    COALESCE(NULLIF(md.keywords, ''), 'No Keywords') AS keywords,
    md.info_count,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN md.total_cast > 10 THEN 'Large Cast' 
        WHEN md.total_cast > 5 THEN 'Medium Cast' 
        ELSE 'Small Cast' 
    END AS cast_size
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordStats ks ON md.movie_id = ks.movie_id
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, md.total_cast DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
