WITH RankedMovies AS (
    SELECT 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
RecentMovies AS (
    SELECT 
        title, production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieDetails AS (
    SELECT 
        r.title,
        r.production_year,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') AS cast_details,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No keywords') AS keywords
    FROM 
        RecentMovies r
    LEFT JOIN 
        cast_info c ON r.title = (SELECT title FROM aka_title WHERE id = c.movie_id)
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        r.title, r.production_year
),
FinalOutput AS (
    SELECT 
        md.title,
        md.production_year, 
        md.cast_details,
        md.keywords,
        CASE 
            WHEN md.keywords = 'No keywords' THEN 'Check for tags'
            ELSE 'Keywords present'
        END AS keyword_status
    FROM 
        MovieDetails md
)
SELECT 
    f.title, 
    f.production_year, 
    f.cast_details, 
    f.keywords, 
    f.keyword_status,
    (SELECT COUNT(*) FROM movie_info WHERE movie_id IN (SELECT id FROM aka_title WHERE title = f.title)) AS info_count
FROM 
    FinalOutput f
ORDER BY 
    f.production_year DESC, f.keywords;
