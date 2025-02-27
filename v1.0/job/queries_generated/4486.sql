WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_per_year <= 5
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actor_names,
        GROUP_CONCAT(DISTINCT ci.note ORDER BY ci.note) AS character_notes
    FROM 
        TopMovies m
    LEFT JOIN 
        cast_info ci ON m.title = (SELECT a.title FROM aka_title a WHERE a.id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        m.title, m.production_year
),
FinalOutput AS (
    SELECT 
        md.title,
        md.production_year,
        COALESCE(md.actor_names, 'No Actors') AS actor_names,
        COALESCE(md.character_notes, 'No Notes') AS character_notes
    FROM 
        MovieDetails md
    ORDER BY 
        md.production_year DESC, md.title
)

SELECT 
    f.*,
    (SELECT COUNT(DISTINCT mc.company_id)
     FROM movie_companies mc
     JOIN aka_title at ON mc.movie_id = at.id
     WHERE at.title = f.title) AS company_count
FROM 
    FinalOutput f
WHERE 
    f.production_year >= 2000
ORDER BY 
    f.actor_names;
