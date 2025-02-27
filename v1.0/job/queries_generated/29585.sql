WITH FilteredMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        GROUP_CONCAT(DISTINCT aka_name.name) AS aliases,
        GROUP_CONCAT(DISTINCT keyword.keyword) AS keywords
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        aka_name ON aka_title.id = aka_name.id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id
),
CastMembers AS (
    SELECT 
        ci.movie_id,
        GROUP_CONCAT(DISTINCT n.name) AS cast_names,
        COUNT(*) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        name n ON ci.person_id = n.imdb_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.movie_title,
        fm.production_year,
        fm.aliases,
        fm.keywords,
        cm.cast_names,
        cm.total_cast
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CastMembers cm ON fm.movie_id = cm.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aliases,
    md.keywords,
    md.cast_names,
    md.total_cast
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;
