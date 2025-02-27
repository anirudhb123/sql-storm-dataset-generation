WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.kind_id, 
        COUNT(c.cast_info.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.cast_info.id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        array_agg(DISTINCT ak.name) AS aka_names,
        array_agg(DISTINCT p.info) AS person_info,
        array_agg(DISTINCT m.keyword) AS keywords
    FROM 
        TopMovies t
    LEFT JOIN 
        aka_title at ON t.title = at.title AND t.production_year = at.production_year
    LEFT JOIN 
        movie_keyword m ON at.id = m.movie_id
    LEFT JOIN 
        movie_info mi ON at.id = mi.movie_id
    LEFT JOIN 
        person_info p ON p.person_id = mi.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = p.person_id
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    title, 
    production_year, 
    aka_names, 
    person_info, 
    keywords
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, 
    title;
