WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS all_actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name an ON c.person_id = an.person_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.id
),
HighCastMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        kind_id,
        cast_count,
        all_actors,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
),
SelectedMovies AS (
    SELECT 
        a.movie_title,
        a.production_year,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
        a.all_actors,
        a.keywords,
        k.kind AS movie_kind
    FROM 
        HighCastMovies a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    JOIN 
        kind_type k ON a.kind_id = k.id
    WHERE 
        a.rank <= 10
    GROUP BY 
        a.movie_title, a.production_year, a.all_actors, a.keywords, k.kind
)
SELECT 
    movie_title,
    production_year,
    notes_count,
    all_actors,
    keywords,
    movie_kind
FROM 
    SelectedMovies
ORDER BY 
    production_year DESC, movie_title;
