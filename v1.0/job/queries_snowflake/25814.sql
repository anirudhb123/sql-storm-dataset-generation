
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL AND
        a.name IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieInfo AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        mi.info AS movie_description,
        mi.note AS movie_note
    FROM 
        TopMovies AS tm
    LEFT JOIN 
        movie_info AS mi ON tm.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies,
        LISTAGG(DISTINCT ct.kind, ', ') WITHIN GROUP (ORDER BY ct.kind) AS company_types
    FROM 
        TopMovies AS m
    JOIN 
        movie_companies AS mc ON m.movie_id = mc.movie_id
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.movie_id, m.title, m.production_year
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    mi.movie_description,
    mi.movie_note,
    cd.companies,
    cd.company_types
FROM 
    TopMovies AS tm
JOIN 
    MovieInfo AS mi ON tm.movie_id = mi.movie_id
JOIN 
    CompanyDetails AS cd ON tm.movie_id = cd.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
