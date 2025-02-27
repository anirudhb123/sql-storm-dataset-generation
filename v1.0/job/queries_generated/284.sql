WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 3
),
MovieDetails AS (
    SELECT 
        t.title,
        COALESCE(ci.note, 'No role specified') AS role_note,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(sub.ratings) AS average_rating
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN LATERAL (
        SELECT 
            i.info_type_id,
            CAST(i.info AS FLOAT) as ratings
        FROM 
            movie_info i 
        WHERE 
            i.movie_id = t.id AND 
            i.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    ) sub ON true
    GROUP BY 
        t.title, ci.note, c.name, ct.kind
)
SELECT 
    tm.title,
    tm.production_year,
    md.role_note,
    md.company_name,
    md.company_type,
    md.cast_count,
    md.average_rating
FROM 
    TopMovies tm
LEFT JOIN 
    MovieDetails md ON tm.title = md.title
WHERE 
    md.cast_count IS NOT NULL 
    AND md.average_rating IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    md.average_rating DESC;
