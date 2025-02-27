WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, m.md5sum) AS rank_by_year,
        COALESCE(MAX(ci.note), 'No Note') AS cast_note
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_info AS m ON t.movie_id = m.movie_id
    LEFT JOIN 
        cast_info AS ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
AverageCastNotes AS (
    SELECT 
        movie_id, 
        AVG(CASE WHEN note IS NOT NULL THEN LENGTH(note) ELSE 0 END) AS avg_note_length
    FROM 
        cast_info
    GROUP BY 
        movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    CASE 
        WHEN rm.rank_by_year = 1 THEN 'Top Movie of the Year'
        ELSE CAST(rm.rank_by_year AS TEXT) || ' - Rank'
    END AS rank_description,
    ak.name AS actor_name,
    ak.md5sum AS actor_md5sum,
    COALESCE(mk.keywords, 'No Keywords') AS keyword_list,
    a.avg_note_length AS average_note_length,
    CASE 
        WHEN a.avg_note_length > 0 THEN 
            'Average note length is ' || a.avg_note_length || ' characters'
        ELSE 
            'No notes available for this movie.'
    END AS note_length_description
FROM 
    RankedMovies AS rm
LEFT JOIN 
    cast_info AS ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
LEFT JOIN 
    AverageCastNotes AS a ON rm.movie_id = a.movie_id
LEFT JOIN 
    MovieKeywords AS mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.production_year IS NOT NULL 
    AND rm.rank_by_year <= 5
ORDER BY 
    rm.production_year DESC, rm.rank_by_year, ak.name;
