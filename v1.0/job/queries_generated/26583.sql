WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        t.kind_id
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
KeywordMatches AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        RankedMovies m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.num_cast_members,
    rm.cast_names,
    km.keywords,
    kt.kind AS movie_kind
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordMatches km ON rm.movie_id = km.movie_id
LEFT JOIN 
    kind_type kt ON rm.kind_id = kt.id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    rm.num_cast_members DESC;
