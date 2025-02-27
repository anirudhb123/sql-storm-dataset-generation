WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS has_notes_ratio,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.production_year >= 2000
),
GenreCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS genre_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        COALESCE(gc.genre_count, 0) AS genre_count,
        rm.has_notes_ratio,
        rk.rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        GenreCounts gc ON rm.movie_id = gc.movie_id
    WHERE 
        rm.total_cast >= 5
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.total_cast,
    fr.genre_count,
    fr.has_notes_ratio,
    CASE 
        WHEN fr.has_notes_ratio > 0.5 THEN 'Many Notes'
        ELSE 'Few Notes'
    END AS notes_description
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.total_cast DESC;
