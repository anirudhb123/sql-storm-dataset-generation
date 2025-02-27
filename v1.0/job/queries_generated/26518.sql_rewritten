WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighlyRatedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.aka_names,
        m.movie_keywords,
        mi.info AS rating_info
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating') 
),
FinalResults AS (
    SELECT 
        hr.movie_id,
        hr.title,
        hr.production_year,
        hr.cast_count,
        hr.aka_names,
        hr.movie_keywords,
        TRIM(BOTH ' ' FROM hr.rating_info) AS rating 
    FROM 
        HighlyRatedMovies hr
    WHERE 
        hr.cast_count >= 5
    ORDER BY 
        hr.cast_count DESC, hr.production_year DESC
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.aka_names,
    fr.movie_keywords,
    CASE 
        WHEN fr.rating IS NOT NULL THEN 'Rated'
        ELSE 'Unrated'
    END AS rating_status
FROM 
    FinalResults fr
LIMIT 100;