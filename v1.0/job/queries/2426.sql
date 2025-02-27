WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        m.production_year,
        STRING_AGG(DISTINCT m.title, ', ') AS top_movies,
        AVG(k.keyword_length) AS avg_keyword_length
    FROM 
        FilteredMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        (SELECT 
             id, 
             LENGTH(keyword) AS keyword_length 
         FROM 
             keyword) k ON mk.keyword_id = k.id
    GROUP BY 
        m.production_year
)
SELECT 
    pd.production_year,
    pd.top_movies,
    COALESCE(pd.avg_keyword_length, 0) AS avg_keyword_length,
    CASE 
        WHEN pd.avg_keyword_length IS NULL THEN 'No keywords'
        WHEN pd.avg_keyword_length > 0 AND pd.avg_keyword_length < 5 THEN 'Short Keywords'
        ELSE 'Long Keywords'
    END AS keyword_category
FROM 
    MovieDetails pd
ORDER BY 
    pd.production_year DESC;
