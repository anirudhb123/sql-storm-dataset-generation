WITH MovieRankings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS role_count_rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        movie_id,
        title
    FROM 
        MovieRankings
    WHERE 
        role_count_rank <= 5
), 
MovieDetails AS (
    SELECT 
        tm.title,
        tp.name AS top_person,
        mc.name AS company_name,
        ti.info AS movie_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.movie_id = cc.movie_id 
    LEFT JOIN 
        person_info pi ON cc.subject_id = pi.person_id 
    LEFT JOIN 
        name tp ON pi.person_id = tp.imdb_id 
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id 
    LEFT JOIN 
        movie_info ti ON tm.movie_id = ti.movie_id
    WHERE 
        ti.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%budget%')
), 
FinalResults AS (
    SELECT 
        md.title,
        md.top_person,
        md.company_name,
        COALESCE(md.movie_info, 'No info available') AS movie_info
    FROM 
        MovieDetails md
), 
KeywordSummary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    fr.title,
    fr.top_person,
    fr.company_name,
    fr.movie_info,
    ks.keywords
FROM 
    FinalResults fr
LEFT JOIN 
    KeywordSummary ks ON fr.movie_id = ks.movie_id
WHERE 
    fr.company_name IS NOT NULL AND fr.top_person IS NOT NULL
ORDER BY 
    fr.title;
