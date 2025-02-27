WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.title IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(CAST(m.production_year AS TEXT), 'Unknown Year') AS production_year_string,
        CASE 
            WHEN r.rank_by_title = 1 THEN 'First Alphabetically'
            ELSE 'Not First Alphabetically'
        END AS title_rank_status
    FROM 
        RankedMovies r
    JOIN aka_title m ON r.movie_id = m.id
),
CastInfo AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS total_cast,
        MAX(CASE WHEN p.gender = 'F' THEN 'Female' ELSE 'Male' END) AS predominant_gender
    FROM 
        cast_info c
    JOIN name p ON c.person_id = p.id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.title,
    md.production_year_string,
    COALESCE(ci.total_cast, 0) AS total_cast_members,
    ci.predominant_gender,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    (SELECT COUNT(*)
     FROM movie_keyword mk
     WHERE mk.movie_id = md.movie_id) AS keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    CastInfo ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id IN (
        SELECT 
            c.person_id
        FROM 
            cast_info c
        WHERE 
            c.movie_id = md.movie_id
    )
GROUP BY 
    md.movie_id, md.title, md.production_year_string, ci.total_cast, ci.predominant_gender
HAVING 
    md.production_year_string != 'Unknown Year' -- Ensuring we get movies with known years
ORDER BY 
    md.production_year DESC, md.title
FETCH FIRST 10 ROWS ONLY;
