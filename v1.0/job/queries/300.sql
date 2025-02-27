WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(ci.nr_order), 0) AS total_cast_members
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.rank_by_year <= 5
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, k.keyword
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.production_companies,
    pi.info AS director_info
FROM 
    MovieDetails md
LEFT JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
WHERE 
    md.production_companies > 0
ORDER BY 
    md.production_year DESC, md.title;
