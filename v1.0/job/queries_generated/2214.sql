WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(mci.note, 'No Company Info') AS company_note
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mci ON fm.movie_id = mci.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.company_note, ', ') AS company_notes
FROM 
    MovieDetails md
LEFT JOIN 
    movie_info mi ON md.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
GROUP BY 
    md.title, md.production_year, md.actor_count
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
