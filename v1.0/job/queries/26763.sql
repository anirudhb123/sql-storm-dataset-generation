
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(c.id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title m
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
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
MovieGenres AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(kt.kind, ', ') AS genres
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        kind_type kt ON ct.id = kt.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.total_cast_members,
    rm.actor_names,
    mk.keywords,
    mg.genres
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast_members DESC;
