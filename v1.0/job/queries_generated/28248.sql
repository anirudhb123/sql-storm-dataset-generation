WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS a
    JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info AS c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        COALESCE(MAX(ci.note), 'No Note') AS cast_note,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        ARRAY_AGG(DISTINCT ct.kind) AS company_types
    FROM 
        FilteredMovies AS fm
    LEFT JOIN 
        complete_cast AS cc ON fm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_companies AS mc ON fm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        fm.movie_id, fm.title
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_note,
    md.company_names,
    md.company_types,
    fm.keyword
FROM 
    MovieDetails AS md
JOIN 
    FilteredMovies AS fm ON md.movie_id = fm.movie_id
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
