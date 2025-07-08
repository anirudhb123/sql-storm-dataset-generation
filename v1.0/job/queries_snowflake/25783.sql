
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
TopRatedMovies AS (
    SELECT 
        rm.* 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank = 1
),
MovieDetails AS (
    SELECT 
        t.title,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS cast_names
    FROM 
        TopRatedMovies t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info ca ON t.movie_id = ca.movie_id
    LEFT JOIN 
        name cn ON ca.person_id = cn.imdb_id
    GROUP BY 
        t.title, c.name, ct.kind
)
SELECT 
    md.title,
    md.company_name,
    md.company_type,
    md.cast_count,
    md.cast_names,
    CASE
        WHEN md.cast_count >= 5 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_category
FROM 
    MovieDetails md
ORDER BY 
    md.cast_count DESC, 
    md.title;
