WITH MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(mk.keywords, '{}') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        MovieKeywords mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, mk.keywords
),
TopMovies AS (
    SELECT 
        md.title,
        md.production_year,
        md.keywords,
        md.cast_names,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC) AS rank
    FROM 
        MovieDetails md
    WHERE 
        'action' = ANY(md.keywords
                      ) OR 'drama' = ANY(md.keywords)
)
SELECT 
    title, 
    production_year, 
    keywords, 
    cast_names
FROM 
    TopMovies
WHERE 
    rank <= 10;