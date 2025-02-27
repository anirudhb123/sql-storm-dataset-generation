
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        a.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id
),
MovieDetails AS (
    SELECT 
        a.id,
        a.title,
        a.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(mc.company_id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        MovieKeywords mk ON a.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, mk.keywords
)

SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.company_count,
    CASE 
        WHEN md.company_count > 0 THEN 'Produced'
        ELSE 'Not Produced'
    END AS production_status
FROM 
    MovieDetails md
JOIN 
    TopMovies t ON md.title = t.title AND md.production_year = t.production_year
ORDER BY 
    md.production_year DESC, 
    md.company_count DESC;
