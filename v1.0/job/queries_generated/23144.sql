WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        c.person_id,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY t.production_year DESC) AS rn,
        COALESCE(NULLIF(c.note, ''), 'No Note') AS cast_note,
        LENGTH(t.title) AS title_length
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND a.name_pcode_cf IS NOT NULL
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
),
FilteredMovies AS (
    SELECT 
        rm.aka_id,
        rm.title,
        rm.person_id,
        rm.production_year,
        rm.cast_note,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.aka_id = mk.movie_id
    WHERE 
        rm.rn = 1
        AND rm.production_year > 2000
)
SELECT 
    f.title,
    f.production_year,
    f.keywords,
    COUNT(DISTINCT f.person_id) AS actor_count,
    AVG(NULLIF(f.title_length, 0)) AS avg_title_length
FROM 
    FilteredMovies f
LEFT JOIN 
    info_type it ON f.cast_note = it.info
GROUP BY 
    f.title, f.production_year, f.keywords
HAVING 
    COUNT(DISTINCT f.person_id) > 2
ORDER BY 
    f.production_year DESC, avg_title_length DESC
LIMIT 10;

WITH MostCollaborative AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT f.title) AS collaboration_count
    FROM 
        FilteredMovies f
    JOIN 
        cast_info c ON f.person_id = c.person_id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT f.title) > 3
)
SELECT 
    m.name,
    mc.collaboration_count
FROM 
    MostCollaborative mc
JOIN 
    aka_name m ON mc.person_id = m.person_id
ORDER BY 
    mc.collaboration_count DESC;

