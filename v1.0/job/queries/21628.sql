WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT * 
    FROM RankedMovies 
    WHERE rank_within_year <= 5
),
MovieDetails AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        COALESCE(cn.name, 'Unknown') AS company_name,
        CASE 
            WHEN mm.production_year IS NULL THEN 'Upcoming'
            ELSE 'Released'
        END AS release_status
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.title_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON tm.title_id = mi.movie_id AND mi.info_type_id = 1
    LEFT JOIN 
        (SELECT DISTINCT production_year FROM aka_title) mm ON mm.production_year > tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.release_status,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    md.title, md.production_year, md.company_name, md.release_status
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 1
ORDER BY 
    md.production_year DESC, md.title;