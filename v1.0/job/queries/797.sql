WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    TRM.title AS top_movie_title,
    TRM.production_year,
    COALESCE(MK.keywords_list, 'No Keywords') AS associated_keywords,
    (SELECT COUNT(DISTINCT ci1.person_id) 
     FROM cast_info ci1 
     WHERE ci1.movie_id = TRM.movie_id) AS total_cast,
    (SELECT 
        MAX(length(name)) 
     FROM 
        aka_name 
     WHERE 
        person_id IN (SELECT DISTINCT ci2.person_id FROM cast_info ci2 WHERE ci2.movie_id = TRM.movie_id)
    ) AS max_name_length
FROM 
    TopRankedMovies TRM
LEFT JOIN 
    MovieKeywords MK ON TRM.movie_id = MK.movie_id
ORDER BY 
    TRM.production_year DESC, 
    TRM.title;
