WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_within_year <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    mk.keywords,
    COALESCE(pi.info, 'No description available') AS person_info,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    NULLIF(SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END), 0) AS lead_count
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography' LIMIT 1)
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, mk.keywords, pi.info
ORDER BY 
    tm.production_year DESC, tm.title;
