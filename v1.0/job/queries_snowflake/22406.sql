
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        TopMovies m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
CastDetails AS (
    SELECT 
        C.person_id,
        NAME.name,
        COUNT(DISTINCT C.movie_id) AS movies_played,
        MAX(CASE WHEN C.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes
    FROM 
        cast_info C
    INNER JOIN 
        aka_name NAME ON C.person_id = NAME.person_id
    GROUP BY 
        C.person_id, NAME.name
)
SELECT 
    TM.title,
    TM.production_year,
    KM.keyword,
    CD.name,
    CD.movies_played,
    CASE 
        WHEN CD.movies_played > 1 AND CD.has_notes = 1 THEN 'Multiple movies with notes'
        WHEN CD.movies_played > 1 THEN 'Multiple movies'
        ELSE 'Single movie or no notes' 
    END AS notes_summary
FROM 
    TopMovies TM
LEFT JOIN 
    MovieKeywords KM ON TM.movie_id = KM.movie_id AND KM.keyword_rank <= 3
LEFT JOIN 
    CastDetails CD ON TM.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = CD.person_id LIMIT 1)
ORDER BY 
    TM.production_year DESC, 
    TM.cast_count DESC, 
    KM.keyword ASC; 
