WITH RankedMovies AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(a.name, ', ') AS cast_names,
        AVG(pi.info) AS avg_person_info_length
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    rm.cast_names,
    mk.keywords_list,
    rm.avg_person_info_length
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
