WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    JOIN 
        cast_info c ON mt.id = c.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN t.production_year < 2000 THEN 'Classic'
        WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info_count
FROM 
    TopMovies t
LEFT JOIN 
    MovieKeywords mk ON t.movie_id = mk.movie_id
ORDER BY 
    t.production_year DESC, 
    t.title;
