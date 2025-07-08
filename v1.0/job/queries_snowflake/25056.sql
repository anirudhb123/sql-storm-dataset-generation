
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
    GROUP BY 
        t.id, t.title, t.production_year
), 
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        companies,
        keywords,
        cast_count,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    rank,
    movie_title,
    production_year,
    companies,
    keywords,
    cast_count
FROM 
    RankedMovies
WHERE 
    rank <= 10;
