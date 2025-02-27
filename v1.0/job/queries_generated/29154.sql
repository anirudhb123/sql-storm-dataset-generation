WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(c.person_id) AS number_of_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ak ON ak.person_id = c.person_id  
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.movie_id
), 
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.number_of_cast_members,
        rm.cast_names,
        mi.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieInfo mi ON rm.id = mi.movie_id
    WHERE 
        rm.number_of_cast_members > 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.number_of_cast_members,
    fm.cast_names,
    fm.keywords
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.number_of_cast_members DESC;
