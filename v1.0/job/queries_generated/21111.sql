WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
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
        actor_count_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        COALESCE(p.gender, 'Unknown') AS gender,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        tm.title, tm.production_year, mk.keyword, p.gender
),
MovieStats AS (
    SELECT 
        title,
        production_year,
        keyword,
        gender,
        total_cast,
        AVG(total_cast) OVER (PARTITION BY production_year) AS avg_cast_per_year
    FROM 
        MovieDetails
),
FinalStats AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.keyword,
        ms.gender,
        ms.total_cast,
        ms.avg_cast_per_year,
        CASE 
            WHEN ms.total_cast > ms.avg_cast_per_year THEN 'Above Average' 
            WHEN ms.total_cast < ms.avg_cast_per_year THEN 'Below Average' 
            ELSE 'Average' 
        END AS cast_status
    FROM 
        MovieStats ms
)
SELECT 
    fs.*
FROM 
    FinalStats fs
WHERE 
    fs.keyword != 'No Keyword'
ORDER BY 
    fs.production_year DESC, 
    fs.total_cast DESC;
